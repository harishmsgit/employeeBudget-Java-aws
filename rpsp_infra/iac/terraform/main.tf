locals {
  name_prefix = "dda-${var.environment}"
}

# ── ECR ──────────────────────────────────────────────────────────────────────
module "ecr" {
  source       = "./modules/ecr"
  environment  = var.environment
  repositories = var.ecr_repositories
}

# ── Lambda (short-execution event handler) ───────────────────────────────────
module "lambda" {
  source                 = "./modules/lambda"
  environment            = var.environment
  name_prefix            = local.name_prefix
  vpc_id                 = var.vpc_id
  subnet_ids             = var.private_subnet_ids
  security_group_ids     = var.lambda_security_group_ids
  sns_topic_arn          = var.sns_topic_arn
  lambda_source_dir      = "${path.root}/../lambda/short-execution"
}

# ── AWS Batch (nightly job) ──────────────────────────────────────────────────
module "batch" {
  source             = "./modules/batch"
  environment        = var.environment
  name_prefix        = local.name_prefix
  vpc_id             = var.vpc_id
  subnet_ids         = var.private_subnet_ids
  security_group_ids = var.batch_security_group_ids
  archive_s3_bucket  = var.archive_s3_bucket
  db_secret_arn      = var.db_secret_arn
  db_host            = var.db_host
  db_name            = var.db_name
  db_user            = var.db_user
  sns_topic_arn      = var.sns_topic_arn
  nightly_cron       = var.batch_nightly_cron
  batch_image        = module.ecr.repository_urls["batch-night-job"]
}
