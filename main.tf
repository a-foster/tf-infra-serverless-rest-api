# Main Terraform Configuration
# Provider and core data sources

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 5.0.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
    }
  }
}

# Data sources for account information
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  # Automatically determine if GitHub Actions should be enabled
  enable_github_actions = var.enable_github_actions != null ? var.enable_github_actions : (var.github_org != "" && var.github_org != null)

  # Derive API stage name from environment unless explicitly overridden
  api_stage_name = var.api_stage_name != null ? var.api_stage_name : var.environment
}
