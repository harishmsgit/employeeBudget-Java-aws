variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "ap-south-1"
}

variable "environment" {
  type        = string
  description = "Deployment environment: dev | qa | prod"
  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "Must be dev, qa, or prod."
  }
}

variable "eks_cluster_name" {
  type        = string
  description = "Existing EKS cluster name"
  default     = "webapp-eks-cluster"
}

variable "node_group_name" {
  type        = string
  description = "Existing EKS managed node group name"
  default     = "JavaSpringNG"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for Lambda and Batch network placement"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs (at least 2 AZs)"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs (optional, reserved for ingress/NAT/alb use-cases)"
  default     = []
}

variable "lambda_security_group_ids" {
  type        = list(string)
  description = "Security groups for Lambda functions (needs egress to RDS/SQS/SNS)"
  default     = []
}

variable "batch_security_group_ids" {
  type        = list(string)
  description = "Security groups for Batch Fargate tasks"
  default     = []
}

variable "archive_s3_bucket" {
  type        = string
  description = "S3 bucket name for batch archives and reports"
}

variable "db_secret_arn" {
  type        = string
  description = "Secrets Manager ARN containing DB credentials JSON"
  sensitive   = true
}

variable "db_host" {
  type        = string
  description = "PostgreSQL host endpoint (RDS/Aurora)"
  default     = ""
}

variable "db_name" {
  type        = string
  description = "Database name for batch job"
  default     = "app_db"
}

variable "db_user" {
  type        = string
  description = "Database username"
  default     = "postgres"
}

variable "sns_topic_arn" {
  type        = string
  description = "SNS topic ARN for Lambda and Batch alerts (optional)"
  default     = ""
}

variable "batch_nightly_cron" {
  type        = string
  description = "EventBridge cron expression for nightly batch (UTC)"
  default     = "cron(0 1 * * ? *)"
}

variable "ecr_repositories" {
  type        = list(string)
  description = "ECR repository names to provision"
  default     = ["employee-service", "project-service", "budget-service", "batch-night-job"]
}
