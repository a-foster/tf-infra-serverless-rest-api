# Lambda Function
# Containerized Lambda function with OpenTelemetry instrumentation

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days

  tags = merge(
    {
      Name        = "${var.function_name}-logs"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_lambda_function" "lambda_function" {
  function_name = var.function_name
  role          = aws_iam_role.lambda_execution.arn
  package_type  = "Image"
  image_uri     = var.image_uri

  memory_size = var.memory_size
  timeout     = var.timeout

  environment {
    variables = {
      ENVIRONMENT             = var.environment
      LOG_LEVEL               = var.log_level
      POWERTOOLS_SERVICE_NAME = var.function_name

      # OpenTelemetry configuration
      OTEL_SERVICE_NAME        = var.function_name
      OTEL_RESOURCE_ATTRIBUTES = "service.name=${var.function_name},deployment.environment=${var.environment}"

      # AWS X-Ray exporter
      OTEL_TRACES_EXPORTER        = "otlp"
      OTEL_EXPORTER_OTLP_PROTOCOL = "http/protobuf"
      OTEL_EXPORTER_OTLP_ENDPOINT = "http://localhost:4318"

      # Use AWS X-Ray for tracing
      AWS_XRAY_DAEMON_ADDRESS = "127.0.0.1:2000"
    }
  }

  tracing_config {
    mode = var.tracing_mode
  }

  # Lifecycle configuration to prevent Terraform from reverting image updates made by CI/CD
  lifecycle {
    ignore_changes = [
      image_uri,
      # Allow CI/CD to update the image without Terraform reverting it
    ]
  }

  tags = merge(
    {
      Name        = var.function_name
      Environment = var.environment
      Framework   = "OpenTelemetry"
    },
    var.tags
  )

  depends_on = [
    aws_iam_role_policy.lambda_execution,
    aws_cloudwatch_log_group.lambda
  ]
}

# Lambda Function Alias (optional, useful for versioning)
resource "aws_lambda_alias" "live" {
  name             = "live"
  description      = "Live alias for ${var.function_name}"
  function_name    = aws_lambda_function.lambda_function.function_name
  function_version = "$LATEST"
}
