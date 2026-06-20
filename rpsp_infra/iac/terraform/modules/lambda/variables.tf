variable "environment"        { type = string }
variable "name_prefix"        { type = string }
variable "vpc_id"             { type = string }
variable "subnet_ids"         { type = list(string) }
variable "security_group_ids" {
	type    = list(string)
	default = []
}
variable "sns_topic_arn" {
	type    = string
	default = ""
}
variable "lambda_source_dir" {
	type        = string
	description = "Path to Python source directory"
}
