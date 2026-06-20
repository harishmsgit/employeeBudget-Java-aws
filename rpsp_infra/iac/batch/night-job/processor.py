"""
Nightly Batch Processor
========================
Triggered : EventBridge cron → AWS Batch (Fargate) at 01:00 UTC
Max runtime: 2 hours
Purpose   :
  1. Budget reconciliation  — planned vs actual spend per project
  2. Project daily snapshot — aggregate health metrics
  3. Employee activity report — count + upload to S3
  4. Record archival         — move 90-day-old budgets to S3

Environment variables (injected by Terraform):
  DB_HOST, DB_NAME, DB_USER, DB_SECRET_ARN,
  ARCHIVE_S3_BUCKET, SNS_TOPIC_ARN, ENVIRONMENT
"""

from __future__ import annotations

import json
import logging
import os
import sys
from datetime import date, datetime
from typing import Any

import boto3
import psycopg2
import psycopg2.extras

# ─────────────────────────────────────────────────────────────────────────────
# Logging
# ─────────────────────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s [%(name)s] %(message)s",
    stream=sys.stdout,
)
logger = logging.getLogger("night-job")


# ─────────────────────────────────────────────────────────────────────────────
# Processor
# ─────────────────────────────────────────────────────────────────────────────

class NightlyBatchProcessor:
    """Orchestrates all nightly jobs with single DB transaction per job."""

    _s3: Any = None
    _sns: Any = None

    def __init__(self) -> None:
        self.environment = os.environ["ENVIRONMENT"]
        self.db_host = os.environ["DB_HOST"]
        self.db_port = int(os.environ.get("DB_PORT", "5432"))
        self.db_name = os.environ["DB_NAME"]
        self.db_user = os.environ["DB_USER"]
        self.db_password = self._get_secret(os.environ["DB_SECRET_ARN"])
        self.s3_bucket = os.environ["ARCHIVE_S3_BUCKET"]
        self.sns_topic_arn = os.environ.get("SNS_TOPIC_ARN", "")
        self.conn: Any = None

    # ── AWS helpers ───────────────────────────────────────────────────────────

    def _get_secret(self, secret_arn: str) -> str:
        client = boto3.client("secretsmanager")
        resp = client.get_secret_value(SecretId=secret_arn)
        return json.loads(resp["SecretString"])["password"]

    @property
    def s3(self) -> Any:
        if self._s3 is None:
            self._s3 = boto3.client("s3")
        return self._s3

    @property
    def sns(self) -> Any:
        if self._sns is None:
            self._sns = boto3.client("sns")
        return self._sns

    # ── DB lifecycle ──────────────────────────────────────────────────────────

    def connect(self) -> None:
        self.conn = psycopg2.connect(
            host=self.db_host,
            port=self.db_port,
            dbname=self.db_name,
            user=self.db_user,
            password=self.db_password,
            connect_timeout=10,
            sslmode="require",
            options="-c statement_timeout=300000",  # 5 min per statement
        )
        self.conn.autocommit = False
        logger.info("DB connected: %s/%s", self.db_host, self.db_name)

    def disconnect(self) -> None:
        if self.conn:
            self.conn.close()
            self.conn = None
            logger.info("DB disconnected")

    # ── Main orchestration ────────────────────────────────────────────────────

    def run(self) -> None:
        run_date = date.today()
        logger.info("=== Nightly batch START — %s [%s] ===", run_date, self.environment)
        results: dict = {}

        self.connect()
        try:
            results["budget_reconciliation"] = self._reconcile_budgets(run_date)
            results["project_snapshot"] = self._snapshot_projects(run_date)
            results["employee_report"] = self._employee_report(run_date)
            results["archive"] = self._archive_old_budgets(run_date)
            self.conn.commit()
            logger.info("=== Nightly batch COMMITTED ===")
        except Exception as exc:
            self.conn.rollback()
            logger.error("=== Nightly batch ROLLED BACK: %s ===", exc)
            self._alert_failure(str(exc))
            sys.exit(1)
        finally:
            self.disconnect()

        self._alert_success(run_date, results)
        logger.info("=== Nightly batch COMPLETE: %s ===", json.dumps(results, default=str))

    # ── Job 1 — Budget reconciliation ─────────────────────────────────────────

    def _reconcile_budgets(self, run_date: date) -> dict:
        logger.info("[1/4] Budget reconciliation")
        with self.conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO budget_reconciliation_log
                    (run_date, project_id, planned_amount, actual_amount, variance, created_at)
                SELECT
                    %s                                        AS run_date,
                    b.project_id,
                    b.amount                                  AS planned_amount,
                    COALESCE(s.actual_spend, 0)               AS actual_amount,
                    b.amount - COALESCE(s.actual_spend, 0)    AS variance,
                    NOW()
                FROM budgets b
                LEFT JOIN (
                    SELECT project_id, SUM(spend) AS actual_spend
                    FROM   project_spend_entries
                    WHERE  spend_date = %s
                    GROUP  BY project_id
                ) s ON s.project_id = b.project_id
                ON CONFLICT (run_date, project_id)
                DO UPDATE SET
                    actual_amount = EXCLUDED.actual_amount,
                    variance      = EXCLUDED.variance,
                    updated_at    = NOW()
                """,
                (run_date, run_date),
            )
            count = cur.rowcount
        logger.info("  → %d projects reconciled", count)
        return {"rows": count}

    # ── Job 2 — Project daily snapshot ───────────────────────────────────────

    def _snapshot_projects(self, run_date: date) -> dict:
        logger.info("[2/4] Project daily snapshot")
        with self.conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO project_daily_snapshot
                    (snapshot_date, project_id, status, total_budget, spent_to_date, created_at)
                SELECT
                    %s,
                    p.id,
                    p.status,
                    COALESCE(b.amount, 0),
                    COALESCE(s.total_spent, 0),
                    NOW()
                FROM projects p
                LEFT JOIN budgets b ON b.project_id = p.id
                LEFT JOIN (
                    SELECT project_id, SUM(spend) AS total_spent
                    FROM   project_spend_entries
                    WHERE  spend_date <= %s
                    GROUP  BY project_id
                ) s ON s.project_id = p.id
                ON CONFLICT (snapshot_date, project_id) DO NOTHING
                """,
                (run_date, run_date),
            )
            count = cur.rowcount
        logger.info("  → %d snapshots written", count)
        return {"rows": count}

    # ── Job 3 — Employee activity report ─────────────────────────────────────

    def _employee_report(self, run_date: date) -> dict:
        logger.info("[3/4] Employee activity report")
        with self.conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
            cur.execute(
                """
                SELECT
                    COUNT(*)                                         AS total,
                    COUNT(*) FILTER (WHERE role = 'MANAGER')        AS managers,
                    COUNT(*) FILTER (WHERE role = 'DEVELOPER')      AS developers,
                    COUNT(*) FILTER (WHERE role = 'ANALYST')        AS analysts
                FROM employees
                """
            )
            row = cur.fetchone()

        report = {
            "run_date": str(run_date),
            "generated_at": datetime.utcnow().isoformat() + "Z",
            "environment": self.environment,
            "totals": {
                "total": row["total"],
                "managers": row["managers"],
                "developers": row["developers"],
                "analysts": row["analysts"],
            },
        }

        key = f"reports/employee-activity/{run_date}/summary.json"
        self.s3.put_object(
            Bucket=self.s3_bucket,
            Key=key,
            Body=json.dumps(report, indent=2),
            ContentType="application/json",
            ServerSideEncryption="AES256",
        )
        logger.info("  → report uploaded to s3://%s/%s", self.s3_bucket, key)
        return {"total_employees": row["total"], "s3_key": key}

    # ── Job 4 — Archive old budget records ────────────────────────────────────

    def _archive_old_budgets(self, run_date: date) -> dict:
        logger.info("[4/4] Archiving records older than 90 days")
        archived = 0
        with self.conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
            cur.execute(
                """
                SELECT id, project_id, amount, currency
                FROM   budgets
                WHERE  created_at < NOW() - INTERVAL '90 days'
                  AND  archived IS DISTINCT FROM TRUE
                LIMIT  5000
                FOR    UPDATE SKIP LOCKED
                """
            )
            rows = cur.fetchall()
            if rows:
                archive_payload = [
                    {
                        "id": r["id"],
                        "project_id": r["project_id"],
                        "amount": str(r["amount"]),
                        "currency": r["currency"],
                    }
                    for r in rows
                ]
                key = f"archive/budgets/{run_date}/batch-{datetime.utcnow().strftime('%H%M%S')}.json"
                self.s3.put_object(
                    Bucket=self.s3_bucket,
                    Key=key,
                    Body=json.dumps(archive_payload),
                    ContentType="application/json",
                    ServerSideEncryption="AES256",
                )
                ids = [r["id"] for r in rows]
                cur.execute(
                    "UPDATE budgets SET archived = TRUE, archived_at = NOW() WHERE id = ANY(%s)",
                    (ids,),
                )
                archived = len(ids)
                logger.info("  → %d records archived to s3://%s/%s", archived, self.s3_bucket, key)
        return {"archived_count": archived}

    # ── Notifications ─────────────────────────────────────────────────────────

    def _alert_success(self, run_date: date, results: dict) -> None:
        if not self.sns_topic_arn:
            return
        self.sns.publish(
            TopicArn=self.sns_topic_arn,
            Subject=f"[SUCCESS] DDA Nightly Batch — {run_date} [{self.environment}]",
            Message=json.dumps(results, indent=2, default=str),
        )

    def _alert_failure(self, error: str) -> None:
        if not self.sns_topic_arn:
            return
        self.sns.publish(
            TopicArn=self.sns_topic_arn,
            Subject=f"[FAILURE] DDA Nightly Batch — {date.today()} [{self.environment}]",
            Message=f"Nightly batch job failed:\n\n{error}",
        )


# ─────────────────────────────────────────────────────────────────────────────
# Entry point
# ─────────────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    NightlyBatchProcessor().run()
