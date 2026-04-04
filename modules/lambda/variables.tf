# Lambda Module Variables

# ============================================================================
# Required Variables
# ============================================================================

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "image_uri" {
  description = "ECR image URI for the Lambda function"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "aws_region" {
  description = "AWS region for IAM policy ARN construction"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID for IAM policy ARN construction"
  type        = string
}

# ============================================================================
# Lambda Configuration
# ============================================================================

variable "memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 512
}

variable "timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 30
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention in days"
  type        = number
  default     = 30
}

variable "tracing_mode" {
  description = "X-Ray tracing mode (Active or PassThrough)"
  type        = string
  default     = "Active"
}

variable "log_level" {
  description = "Application log level"
  type        = string
  default     = "INFO"
}

# ============================================================================
# Alarm Configuration
# ============================================================================

variable "error_threshold" {
  description = "Threshold for Lambda errors alarm"
  type        = number
  default     = 5
}

variable "throttle_threshold" {
  description = "Threshold for Lambda throttles alarm"
  type        = number
  default     = 10
}

variable "duration_threshold" {
  description = "Threshold for Lambda duration alarm (milliseconds)"
  type        = number
  default     = 5000
}

variable "concurrent_execution_threshold" {
  description = "Threshold for Lambda concurrent executions alarm"
  type        = number
  default     = 100
}

# ============================================================================
# API Gateway Integration
# ============================================================================

variable "api_gateway_execution_arn" {
  description = "API Gateway execution ARN for Lambda permission"
  type        = string
}

# ============================================================================
# Tags
# ============================================================================

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
