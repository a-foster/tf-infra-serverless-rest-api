# Input Variables

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "sano-interview"
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "hello-world-api"
}

variable "lambda_memory_size" {
  description = "Amount of memory in MB for Lambda function"
  type        = number
  default     = 512
}

variable "lambda_timeout" {
  description = "Timeout in seconds for Lambda function"
  type        = number
  default     = 30
}

variable "github_org" {
  description = "GitHub organization or username (leave empty to skip GitHub Actions setup)"
  type        = string
  default     = ""
}

variable "github_repo_infra" {
  description = "GitHub repository name for infrastructure (only used if github_org is set)"
  type        = string
  default     = "tf-infra-serverless-rest-api"
}

variable "github_repo_app" {
  description = "GitHub repository name for application (only used if github_org is set)"
  type        = string
  default     = "hello-world-app"
}

variable "enable_github_actions" {
  description = "Enable GitHub Actions OIDC setup (automatically determined from github_org)"
  type        = bool
  default     = null
}

locals {
  # Automatically determine if GitHub Actions should be enabled
  enable_github_actions = var.enable_github_actions != null ? var.enable_github_actions : (var.github_org != "" && var.github_org != null)
}

variable "api_stage_name" {
  description = "API Gateway deployment stage name"
  type        = string
  default     = "prod"
}
