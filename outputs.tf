# Terraform Outputs
# These values are used by the application repo for CI/CD

output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "aws_account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "ecr_repository_url" {
  description = "ECR repository URL for Docker images"
  value       = aws_ecr_repository.lambda_container.repository_url
}

output "ecr_repository_name" {
  description = "ECR repository name"
  value       = aws_ecr_repository.lambda_container.name
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = module.lambda.function_name
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = module.lambda.function_arn
}

output "api_gateway_endpoint" {
  description = "API Gateway invoke URL"
  value       = "https://${aws_api_gateway_rest_api.main.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.main.stage_name}"
}

output "api_gateway_id" {
  description = "API Gateway REST API ID"
  value       = aws_api_gateway_rest_api.main.id
}

output "github_oidc_role_arn_infra" {
  description = "IAM role ARN for GitHub Actions (infrastructure repo) - null if GitHub Actions not enabled"
  value       = local.enable_github_actions ? aws_iam_role.github_actions_infra[0].arn : null
}

output "github_oidc_role_arn_app" {
  description = "IAM role ARN for GitHub Actions (application repo) - null if GitHub Actions not enabled"
  value       = local.enable_github_actions ? aws_iam_role.github_actions_app[0].arn : null
}

output "github_actions_enabled" {
  description = "Whether GitHub Actions OIDC integration is enabled"
  value       = local.enable_github_actions
}

output "terraform_state_bucket" {
  description = "S3 bucket name for Terraform state (managed separately)"
  value       = "sano-interview-terraform-state-${data.aws_caller_identity.current.account_id}"
}

output "terraform_state_lock_table" {
  description = "DynamoDB table name for Terraform state locking (managed separately)"
  value       = "sano-interview-terraform-locks"
}
