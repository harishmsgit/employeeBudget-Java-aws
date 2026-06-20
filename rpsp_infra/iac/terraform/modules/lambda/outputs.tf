output "function_arn"    { value = aws_lambda_function.short_execution.arn }
output "function_name"   { value = aws_lambda_function.short_execution.function_name }
output "event_queue_url" { value = aws_sqs_queue.event_queue.url }
output "event_queue_arn" { value = aws_sqs_queue.event_queue.arn }
output "dlq_url"         { value = aws_sqs_queue.dlq.url }
