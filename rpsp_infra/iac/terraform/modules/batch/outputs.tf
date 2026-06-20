output "job_queue_arn"           { value = aws_batch_job_queue.nightly.arn }
output "job_definition_arn"      { value = aws_batch_job_definition.night_job.arn }
output "compute_environment_arn" { value = aws_batch_compute_environment.nightly.arn }
output "log_group_name"          { value = aws_cloudwatch_log_group.batch.name }
