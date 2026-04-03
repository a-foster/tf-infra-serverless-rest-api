# Lambda Function
# Containerized Lambda function for the Hello World API

# Note: For initial deployment, you need to push a Docker image to ECR first
# The image URI should be: <account_id>.dkr.ecr.<region>.amazonaws.com/<repo_name>:latest

locals {
  # Construct the initial image URI - this assumes an image with tag "latest" exists or will be pushed
  lambda_image_uri = "${aws_ecr_repository.lambda_container.repository_url}:latest"
}

resource "aws_lambda_function" "hello_world" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_execution.arn
  package_type  = "Image"
  image_uri     = local.lambda_image_uri

  memory_size = var.lambda_memory_size
  timeout     = var.lambda_timeout

  environment {
    variables = {
      ENVIRONMENT             = var.environment
      LOG_LEVEL               = "INFO"
      POWERTOOLS_SERVICE_NAME = var.lambda_function_name

      # OpenTelemetry configuration
      OTEL_SERVICE_NAME        = var.lambda_function_name
      OTEL_RESOURCE_ATTRIBUTES = "service.name=${var.lambda_function_name},deployment.environment=${var.environment}"

      # AWS X-Ray exporter
      OTEL_TRACES_EXPORTER        = "otlp"
      OTEL_EXPORTER_OTLP_PROTOCOL = "http/protobuf"
      OTEL_EXPORTER_OTLP_ENDPOINT = "http://localhost:4318"

      # Use AWS X-Ray for tracing
      AWS_XRAY_DAEMON_ADDRESS = "127.0.0.1:2000"
    }
  }

  tracing_config {
    mode = "Active"
  }

  # Lifecycle configuration to prevent Terraform from reverting image updates made by CI/CD
  lifecycle {
    ignore_changes = [
      image_uri,
      # Allow CI/CD to update the image without Terraform reverting it
    ]
  }

  tags = {
    Name        = var.lambda_function_name
    Environment = var.environment
    Framework   = "OpenTelemetry"
  }

  depends_on = [
    aws_iam_role_policy.lambda_execution,
    aws_cloudwatch_log_group.lambda
  ]
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 30

  tags = {
    Name        = "${var.lambda_function_name}-logs"
    Environment = var.environment
  }
}

# Lambda Function Alias (optional, useful for versioning)
resource "aws_lambda_alias" "live" {
  name             = "live"
  description      = "Live alias for ${var.lambda_function_name}"
  function_name    = aws_lambda_function.hello_world.function_name
  function_version = "$LATEST"
}
