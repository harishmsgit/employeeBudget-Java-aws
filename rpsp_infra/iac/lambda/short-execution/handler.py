"""
short-execution Lambda handler
===============================
Purpose : Event-driven, short-lived processing (max 5 min).
Sources : EventBridge domain events, SQS batch records.
Use cases:
  - Employee onboarding notification (SNS)
  - Budget threshold alert (SNS)
  - Project status webhook push
  - SQS batch consumer with partial-failure support
"""

from __future__ import annotations

import json
import logging
import os
import urllib.request
from datetime import datetime
from typing import Any

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

_sns_client: boto3.client | None = None


def _sns() -> boto3.client:
    global _sns_client
    if _sns_client is None:
        _sns_client = boto3.client("sns")
    return _sns_client


# ─────────────────────────────────────────────────────────────────────────────
# Entry point
# ─────────────────────────────────────────────────────────────────────────────

def handler(event: dict, context: Any) -> dict:
    request_id: str = context.aws_request_id
    _log(request_id, "info", "invocation_start",
         source=event.get("source", "unknown"),
         detail_type=event.get("detail-type", ""))

    try:
        if "Records" in event:
            # SQS batch — return partial-failure format
            return _process_sqs(event["Records"], request_id)

        source = event.get("source", "")
        if source == "employee-service":
            return _ok(_process_employee_event(event, request_id))
        if source == "budget-service":
            return _ok(_process_budget_threshold(event, request_id))
        if source == "project-service":
            return _ok(_process_project_webhook(event, request_id))

        _log(request_id, "warning", "unhandled_source", source=source)
        return _ok({"message": "no handler matched", "source": source})

    except Exception as exc:
        _log(request_id, "error", "unhandled_exception", error=str(exc))
        raise


# ─────────────────────────────────────────────────────────────────────────────
# Domain handlers
# ─────────────────────────────────────────────────────────────────────────────

def _process_employee_event(event: dict, request_id: str) -> dict:
    detail = event.get("detail", {})
    action = detail.get("action", "UNKNOWN")
    employee_id = detail.get("employeeId")
    email = detail.get("email", "")

    _log(request_id, "info", "employee_event", employee_id=employee_id, action=action)

    subjects = {
        "CREATED": f"[DDA] Employee {employee_id} onboarded",
        "UPDATED": f"[DDA] Employee {employee_id} profile updated",
        "DELETED": f"[DDA] ALERT — Employee {employee_id} removed",
    }
    messages = {
        "CREATED": f"Employee {employee_id} ({email}) has been onboarded.",
        "UPDATED": f"Employee {employee_id} profile was updated.",
        "DELETED": f"Employee {employee_id} has been removed from the system.",
    }
    if action in subjects:
        _publish(subjects[action], messages[action])

    return {"employeeId": employee_id, "action": action}


def _process_budget_threshold(event: dict, request_id: str) -> dict:
    detail = event.get("detail", {})
    project_id = detail.get("projectId")
    amount = float(detail.get("amount", 0))
    threshold = float(os.environ.get("BUDGET_ALERT_THRESHOLD", "10000"))
    exceeded = amount > threshold

    _log(request_id, "info", "budget_check",
         project_id=project_id, amount=amount, threshold=threshold, exceeded=exceeded)

    if exceeded:
        _publish(
            f"[DDA] Budget Alert — Project {project_id}",
            f"Budget ${amount:,.2f} exceeds threshold ${threshold:,.2f} for project {project_id}."
        )

    return {"projectId": project_id, "amount": amount, "thresholdExceeded": exceeded}


def _process_project_webhook(event: dict, request_id: str) -> dict:
    detail = event.get("detail", {})
    webhook_url = os.environ.get("WEBHOOK_URL", "")
    project_id = detail.get("projectId")

    if webhook_url:
        payload = json.dumps(detail).encode()
        req = urllib.request.Request(
            webhook_url, data=payload, method="POST",
            headers={"Content-Type": "application/json", "X-Source": "dda-lambda"}
        )
        with urllib.request.urlopen(req, timeout=10) as resp:
            status = resp.status
        _log(request_id, "info", "webhook_sent", project_id=project_id, http_status=status)
    else:
        _log(request_id, "warning", "webhook_skipped", reason="WEBHOOK_URL not set")

    return {"projectId": project_id}


def _process_sqs(records: list[dict], request_id: str) -> dict:
    """SQS batch consumer with ReportBatchItemFailures support."""
    failures: list[dict] = []
    for record in records:
        msg_id = record["messageId"]
        try:
            body = json.loads(record["body"])
            _log(request_id, "info", "sqs_record_processed", message_id=msg_id)
            # Extend here: delegate to domain handlers based on body content
        except Exception as exc:
            _log(request_id, "error", "sqs_record_failed", message_id=msg_id, error=str(exc))
            failures.append({"itemIdentifier": msg_id})

    return {"batchItemFailures": failures}


# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

def _publish(subject: str, message: str) -> None:
    topic_arn = os.environ.get("SNS_TOPIC_ARN", "")
    if not topic_arn:
        logger.warning("SNS_TOPIC_ARN not configured — notification skipped")
        return
    _sns().publish(TopicArn=topic_arn, Subject=subject[:100], Message=message)


def _log(request_id: str, level: str, event_type: str, **kwargs: Any) -> None:
    record = {
        "request_id": request_id,
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "event_type": event_type,
        **kwargs,
    }
    getattr(logger, level)(json.dumps(record))


def _ok(data: dict) -> dict:
    return {"statusCode": 200, "body": json.dumps(data)}
