data "aws_region" "current" {}

# ── IAM: Batch service role ───────────────────────────────────────────────────
resource "aws_iam_role" "batch_service" {
  name = "${var.name_prefix}-batch-service-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "batch.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "batch_service" {
  role       = aws_iam_role.batch_service.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

# ── IAM: Batch job role (what the container can do) ───────────────────────────
resource "aws_iam_role" "batch_job" {
  name = "${var.name_prefix}-batch-job-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "batch_job_policy" {
  name = "${var.name_prefix}-batch-job-policy"
  role = aws_iam_role.batch_job.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3ArchiveAccess"
        Effect = "Allow"
        Action = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"]
        Resource = [
          "arn:aws:s3:::${var.archive_s3_bucket}",
          "arn:aws:s3:::${var.archive_s3_bucket}/*"
        ]
      },
      {
        Sid      = "SecretsManager"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = [var.db_secret_arn]
      },
      {
        Sid      = "SNSPublish"
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = var.sns_topic_arn != "" ? [var.sns_topic_arn] : ["*"]
      },
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = ["arn:aws:logs:*:*:*"]
      }
    ]
  })
}

# ── IAM: Fargate task execution role ─────────────────────────────────────────
resource "aws_iam_role" "batch_execution" {
  name = "${var.name_prefix}-batch-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "batch_execution" {
  role       = aws_iam_role.batch_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ── CloudWatch Log Group ──────────────────────────────────────────────────────
resource "aws_cloudwatch_log_group" "batch" {
  name              = "/aws/batch/${var.name_prefix}-night-job"
  retention_in_days = var.environment == "prod" ? 90 : 14
}

# ── Compute Environment (Fargate — no EC2 to manage) ─────────────────────────
resource "aws_batch_compute_environment" "nightly" {
  compute_environment_name = "${var.name_prefix}-nightly-fargate"
  type                     = "MANAGED"
  service_role             = aws_iam_role.batch_service.arn
  state                    = "ENABLED"

  compute_resources {
    type               = "FARGATE"
    max_vcpus          = var.environment == "prod" ? 16 : 4
    subnets            = var.subnet_ids
    security_group_ids = var.security_group_ids
  }

  tags = { Purpose = "nightly-batch", Environment = var.environment }
}

# ── Job Queue ─────────────────────────────────────────────────────────────────
resource "aws_batch_job_queue" "nightly" {
  name     = "${var.name_prefix}-nightly-queue"
  state    = "ENABLED"
  priority = 1

  compute_environment_order {
    order               = 1
    compute_environment = aws_batch_compute_environment.nightly.arn
  }

  tags = { Purpose = "nightly-batch", Environment = var.environment }
}

# ── Job Definition ────────────────────────────────────────────────────────────
resource "aws_batch_job_definition" "night_job" {
  name = "${var.name_prefix}-night-job"
  type = "container"

  platform_capabilities = ["FARGATE"]

  container_properties = jsonencode({
    image            = var.batch_image
    jobRoleArn       = aws_iam_role.batch_job.arn
    executionRoleArn = aws_iam_role.batch_execution.arn

    fargatePlatformConfiguration = { platformVersion = "LATEST" }

    resourceRequirements = [
      { type = "VCPU",   value = "1" },
      { type = "MEMORY", value = "2048" }
    ]

    environment = [
      { name = "ENVIRONMENT",       value = var.environment },
      { name = "ARCHIVE_S3_BUCKET", value = var.archive_s3_bucket },
      { name = "DB_HOST",           value = var.db_host },
      { name = "DB_NAME",           value = var.db_name },
      { name = "DB_USER",           value = var.db_user },
      { name = "DB_SECRET_ARN",     value = var.db_secret_arn },
      { name = "SNS_TOPIC_ARN",     value = var.sns_topic_arn }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.batch.name
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = "night-job"
      }
    }
  })

  retry_strategy {
    attempts = 2
    evaluate_on_exit {
      on_exit_code = "1"
      action       = "RETRY"
    }
    evaluate_on_exit {
      on_exit_code = "0"
      action       = "EXIT"
    }
  }

  timeout {
    attempt_duration_seconds = 7200 # 2-hour hard limit
  }

  tags = { Purpose = "nightly-batch", Environment = var.environment }
}

# ── EventBridge: IAM role to submit Batch jobs ────────────────────────────────
resource "aws_iam_role" "eventbridge_batch" {
  name = "${var.name_prefix}-eventbridge-batch-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "eventbridge_batch" {
  name = "${var.name_prefix}-eventbridge-batch-policy"
  role = aws_iam_role.eventbridge_batch.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["batch:SubmitJob"]
      Resource = [
        aws_batch_job_queue.nightly.arn,
        aws_batch_job_definition.night_job.arn
      ]
    }]
  })
}

# ── EventBridge: Nightly cron rule (01:00 UTC) ────────────────────────────────
resource "aws_cloudwatch_event_rule" "nightly_trigger" {
  name                = "${var.name_prefix}-nightly-batch-trigger"
  description         = "Trigger nightly batch job — ${var.nightly_cron}"
  schedule_expression = var.nightly_cron
  state               = "ENABLED"

  tags = { Purpose = "nightly-batch-schedule", Environment = var.environment }
}

resource "aws_cloudwatch_event_target" "batch_target" {
  rule      = aws_cloudwatch_event_rule.nightly_trigger.name
  target_id = "NightlyBatchJobTarget"
  arn       = aws_batch_job_queue.nightly.arn
  role_arn  = aws_iam_role.eventbridge_batch.arn

  batch_target {
    job_definition = aws_batch_job_definition.night_job.arn
    job_name       = "${var.name_prefix}-nightly-run"
  }
}

# ── CloudWatch alarms ─────────────────────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "batch_failures" {
  alarm_name          = "${var.name_prefix}-batch-job-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FailedJobCount"
  namespace           = "AWS/Batch"
  period              = 3600
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Nightly batch job failed — check /aws/batch logs"
  treat_missing_data  = "notBreaching"

  dimensions    = { JobQueue = aws_batch_job_queue.nightly.name }
  alarm_actions = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []
}
