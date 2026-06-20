terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.58"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }

  # Remote state — configure per environment in environments/<env>/backend.hcl
  # terraform init -backend-config=environments/prod/backend.hcl
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "dda-microservices"
      ManagedBy   = "terraform"
      Environment = var.environment
      Owner       = "platform-team"
      Repository  = "harishmsgit/employeeBudget-Java-aws"
    }
  }
}
