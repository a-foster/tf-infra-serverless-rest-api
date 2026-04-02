# Terraform Backend Configuration
#
# S3 backend for remote state storage with DynamoDB for state locking

terraform {
  backend "s3" {
    bucket         = "sano-interview-terraform-state-324493851630"
    key            = "serverless-api/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "sano-interview-terraform-locks"
  }
}
