output "ecr_repository_urls" {
  description = "Map of service name → ECR URL"
  value       = module.ecr.repository_urls
}

output "lambda_function_arn" {
  description = "Short-execution Lambda ARN"
  value       = module.lambda.function_arn
}

output "lambda_event_queue_url" {
  description = "SQS queue URL that feeds the Lambda"
  value       = module.lambda.event_queue_url
}

output "lambda_dlq_url" {
  description = "Lambda dead-letter queue URL"
  value       = module.lambda.dlq_url
}

output "batch_job_queue_arn" {
  description = "AWS Batch job queue ARN"
  value       = module.batch.job_queue_arn
}

output "batch_job_definition_arn" {
  description = "AWS Batch job definition ARN"
  value       = module.batch.job_definition_arn
}

output "batch_compute_environment_arn" {
  description = "AWS Batch Fargate compute environment ARN"
  value       = module.batch.compute_environment_arn
}
