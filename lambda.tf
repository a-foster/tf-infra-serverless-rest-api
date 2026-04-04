# Lambda Function Module
# Containerized Lambda function with OpenTelemetry observability

# Note: For initial deployment, you need to push a Docker image to ECR first
# The image URI should be: <account_id>.dkr.ecr.<region>.amazonaws.com/<repo_name>:latest

locals {
  # Construct the initial image URI - this assumes an image with tag "latest" exists or will be pushed
  lambda_image_uri = "${aws_ecr_repository.lambda_container.repository_url}:latest"
}

module "lambda" {
  source = "./modules/lambda"

  # Required inputs
  function_name  = var.lambda_function_name
  image_uri      = local.lambda_image_uri
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

  # Tags
  tags = {}
}
