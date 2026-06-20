terraform {
  backend "s3" {
    bucket         = "dda-terraform-state-495013583028"
    key            = "dda/prod/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "dda-terraform-locks"
  }
}

module "iac" {
  source = "../../"

  aws_region         = "ap-south-1"
  environment        = "prod"
  eks_cluster_name   = "webapp-eks-cluster"
  vpc_id             = "vpc-06bbc38be0501663f"
  # webapp-subnet-private1-ap-south-1a, webapp-subnet-private2-ap-south-1b
  private_subnet_ids = ["subnet-0e54df2d816960e00", "subnet-01a80965fe86324ed"]
  # webapp-subnet-public1-ap-south-1a, webapp-subnet-public2-ap-south-1b
  public_subnet_ids  = ["subnet-02fee81603fe57089", "subnet-0a41d7a8d85ac7a34"]
  archive_s3_bucket  = "dda-prod-archive-495013583028"
  db_secret_arn      = "arn:aws:secretsmanager:ap-south-1:495013583028:secret:dda-prod-db-XXXXX"
  db_host            = "REPLACE_WITH_RDS_ENDPOINT"
  db_name            = "app_db"
  db_user            = "postgres"
  sns_topic_arn      = "arn:aws:sns:ap-south-1:495013583028:dda-prod-alerts"
  batch_nightly_cron = "cron(0 1 * * ? *)"
}
