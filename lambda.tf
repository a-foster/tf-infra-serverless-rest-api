# Lambda Function Module
# Containerized Lambda function with OpenTelemetry observability

module "lambda" {
  source = "./modules/lambda"

  # Required inputs
  function_name  = var.lambda_function_name
  environment    = var.environment
  project_name   = var.project_name
  aws_region     = data.aws_region.current.name
  aws_account_id = data.aws_caller_identity.current.account_id

  # Lambda configuration
  memory_size        = var.lambda_memory_size
  timeout            = var.lambda_timeout
  log_retention_days = 30
  tracing_mode       = "Active"
  log_level          = "INFO"

  # Alarm thresholds (using default values from module)
  error_threshold                = 5
  throttle_threshold             = 10
  duration_threshold             = 5000
  concurrent_execution_threshold = 100

  # API Gateway integration
  api_gateway_execution_arn = aws_api_gateway_rest_api.main.execution_arn

  # GitHub Actions integration (optional)
  github_actions_role_arn = local.enable_github_actions ? aws_iam_role.github_actions_app[0].arn : null

  # Tags
  tags = {}
}
