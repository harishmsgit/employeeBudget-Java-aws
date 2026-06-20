data "aws_region" "current" {}

# ── IAM ──────────────────────────────────────────────────────────────────────
resource "aws_iam_role" "lambda_exec" {
  name = "${var.name_prefix}-lambda-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "vpc_access" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "xray" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.name_prefix}-lambda-policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "SNSPublish"
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = var.sns_topic_arn != "" ? [var.sns_topic_arn] : ["*"]
      },
      {
        Sid    = "SQSAccess"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = [aws_sqs_queue.event_queue.arn]
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

# ── Dead Letter Queue ─────────────────────────────────────────────────────────
resource "aws_sqs_queue" "dlq" {
  name                      = "${var.name_prefix}-lambda-dlq"
  message_retention_seconds = 1209600 # 14 days

  tags = { Purpose = "lambda-dlq", Environment = var.environment }
}

# ── Event Queue ───────────────────────────────────────────────────────────────
resource "aws_sqs_queue" "event_queue" {
  name                       = "${var.name_prefix}-event-queue"
  visibility_timeout_seconds = 330 # Must be >= Lambda timeout + buffer
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 20 # Long polling

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })

  tags = { Purpose = "lambda-events", Environment = var.environment }
}

resource "aws_sqs_queue_policy" "event_queue" {
  queue_url = aws_sqs_queue.event_queue.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.event_queue.arn
    }]
  })
}

# ── Lambda package from source ────────────────────────────────────────────────
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.lambda_source_dir
  output_path = "${path.module}/.build/short-execution-${var.environment}.zip"
}

# ── Lambda function ───────────────────────────────────────────────────────────
resource "aws_lambda_function" "short_execution" {
  function_name    = "${var.name_prefix}-short-execution"
  description      = "Short-execution event handler — employee/project/budget events, max 5 min"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "handler.handler"
  runtime          = "python3.12"
  timeout          = 300
  memory_size      = 256
  architectures    = ["arm64"] # Graviton2 — cheaper + faster for Python

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.security_group_ids
  }

  environment {
    variables = {
      ENVIRONMENT            = var.environment
      SNS_TOPIC_ARN          = var.sns_topic_arn
      BUDGET_ALERT_THRESHOLD = "10000"
    }
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.dlq.arn
  }

  tracing_config {
    mode = "Active" # AWS X-Ray
  }

  reserved_concurrent_executions = var.environment == "prod" ? 50 : 10

  tags = { Purpose = "short-execution", Environment = var.environment }
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.short_execution.function_name}"
  retention_in_days = var.environment == "prod" ? 90 : 14
}

# ── SQS → Lambda trigger ──────────────────────────────────────────────────────
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn                   = aws_sqs_queue.event_queue.arn
  function_name                      = aws_lambda_function.short_execution.arn
  batch_size                         = 10
  maximum_batching_window_in_seconds = 5
  function_response_types            = ["ReportBatchItemFailures"]
}

# ── EventBridge rule — route service domain events to Lambda ──────────────────
resource "aws_cloudwatch_event_rule" "service_events" {
  name        = "${var.name_prefix}-service-domain-events"
  description = "Route DDA domain events (employee/project/budget) to Lambda"

  event_pattern = jsonencode({
    source = ["employee-service", "project-service", "budget-service"]
  })
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.service_events.name
  target_id = "ShortExecutionLambda"
  arn       = aws_lambda_function.short_execution.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.short_execution.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.service_events.arn
}

# ── CloudWatch alarms ─────────────────────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.name_prefix}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Lambda error rate exceeded 5 in 1 minute"
  treat_missing_data  = "notBreaching"

  dimensions = { FunctionName = aws_lambda_function.short_execution.function_name }
  alarm_actions = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []
}

resource "aws_cloudwatch_metric_alarm" "dlq_depth" {
  alarm_name          = "${var.name_prefix}-lambda-dlq-depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Messages in Lambda DLQ — investigation required"
  treat_missing_data  = "notBreaching"

  dimensions    = { QueueName = aws_sqs_queue.dlq.name }
  alarm_actions = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []
}
