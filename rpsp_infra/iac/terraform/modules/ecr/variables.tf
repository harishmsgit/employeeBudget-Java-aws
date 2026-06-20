variable "environment" {
  type        = string
  description = "Environment name"
}

variable "repositories" {
  type        = list(string)
  description = "List of ECR repository names to create"
}
