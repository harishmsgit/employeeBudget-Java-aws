terraform {
  backend "s3" {
    bucket         = "harish-terraform-state-bucket"
    key            = "dda-microservices/dev/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    use_lockfile   = true
  }
}

module "iac" {
  source = "../../"

  aws_region         = "ap-south-1"
  environment        = "dev"
  eks_cluster_name   = "java-spring-eks"
  node_group_name    = "JavaSpringNG"
  vpc_id             = "vpc-0714e469a68ae1721"
  # java-spring-subnet-private1-ap-south-1a, java-spring-subnet-private2-ap-south-1b
  private_subnet_ids = ["subnet-05fa07de18677174e", "subnet-05e66df01fb3253ce"]
  # java-spring-subnet-public1-ap-south-1a, java-spring-subnet-public2-ap-south-1b
  public_subnet_ids  = ["subnet-00bf4ffcdb135dfba", "subnet-0fc2c4ee8877b07ba"]
  lambda_security_group_ids = ["sg-0fe408481fc8b427d"]
  batch_security_group_ids  = ["sg-0fe408481fc8b427d"]
  archive_s3_bucket  = "dda-dev-archive-495013583028"
  db_secret_arn      = "arn:aws:secretsmanager:ap-south-1:495013583028:secret:dda-dev-db-XXXXX"
  db_host            = "REPLACE_WITH_RDS_ENDPOINT"
  db_name            = "app_db"
  db_user            = "postgres"
  sns_topic_arn      = ""
  batch_nightly_cron = "cron(0 1 * * ? *)"
}
