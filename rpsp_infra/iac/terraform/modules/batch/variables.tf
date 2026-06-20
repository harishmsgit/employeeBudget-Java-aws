variable "environment"        { type = string }
variable "name_prefix"        { type = string }
variable "vpc_id"             { type = string }
variable "subnet_ids"         { type = list(string) }
variable "security_group_ids" {
	type    = list(string)
	default = []
}
variable "archive_s3_bucket"  { type = string }
variable "db_secret_arn" {
	type      = string
	sensitive = true
}
variable "db_host" {
	type    = string
	default = ""
}
variable "db_name" {
	type    = string
	default = "app_db"
}
variable "db_user" {
	type    = string
	default = "postgres"
}
variable "sns_topic_arn" {
	type    = string
	default = ""
}
variable "nightly_cron" {
	type    = string
	default = "cron(0 1 * * ? *)"
}
variable "batch_image" {
	type        = string
	description = "Docker image URI for the batch job"
}
