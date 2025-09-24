terraform {
  required_version = ">= 1.13.0"

  backend "s3" {
    bucket         = "node-app-terraform-state"         # S3 bucket name (create once manually)
    key            = "global/terraform.tfstate"         # Path inside the bucket
    region         = "us-east-1"                        # Best Region for you
    dynamodb_table = "node-app-terraform-locks"         # DynamoDB table for state locking
    encrypt        = true                               # Encrypt state at rest
  }
}
