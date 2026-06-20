bucket         = "harish-terraform-state-bucket"
key            = "dda-microservices/prod/terraform.tfstate"
region         = "ap-south-1"
encrypt        = true
dynamodb_table = "harish-terraform-state-lock"
