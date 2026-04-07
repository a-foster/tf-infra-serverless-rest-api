# Lambda Module Outputs

output "function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.lambda_function.function_name
}

output "function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.lambda_function.arn
}

output "invoke_arn" {
  description = "Lambda function invoke ARN (for API Gateway integration)"
  value       = aws_lambda_function.lambda_function.invoke_arn
}

output "qualified_arn" {
  description = "Lambda function qualified ARN"
  value       = aws_lambda_function.lambda_function.qualified_arn
}

output "execution_role_arn" {
  description = "IAM execution role ARN"
  value       = aws_iam_role.lambda_execution.arn
}

output "execution_role_name" {
  description = "IAM execution role name"
  value       = aws_iam_role.lambda_execution.name
}

output "log_group_name" {
  description = "CloudWatch Log Group name"
  value       = aws_cloudwatch_log_group.lambda.name
}

output "log_group_arn" {
  description = "CloudWatch Log Group ARN"
  value       = aws_cloudwatch_log_group.lambda.arn
}

output "alias_name" {
  description = "Lambda alias name"
  value       = aws_lambda_alias.live.name
}

output "alias_arn" {
  description = "Lambda alias ARN"
  value       = aws_lambda_alias.live.arn
}
