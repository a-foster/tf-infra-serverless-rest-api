# CloudWatch Alarms for Lambda Function

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.function_name}-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = var.error_threshold
  alarm_description   = "This metric monitors Lambda function errors"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.hello_world.function_name
  }

  tags = merge(
    {
      Name        = "${var.function_name}-errors"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  alarm_name          = "${var.function_name}-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = var.throttle_threshold
  alarm_description   = "This metric monitors Lambda function throttles"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.hello_world.function_name
  }

  tags = merge(
    {
      Name        = "${var.function_name}-throttles"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  alarm_name          = "${var.function_name}-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Average"
  threshold           = var.duration_threshold
  alarm_description   = "This metric monitors Lambda function duration"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.hello_world.function_name
  }

  tags = merge(
    {
      Name        = "${var.function_name}-duration"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_cloudwatch_metric_alarm" "lambda_concurrent_executions" {
  alarm_name          = "${var.function_name}-concurrent-executions"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ConcurrentExecutions"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Maximum"
  threshold           = var.concurrent_execution_threshold
  alarm_description   = "This metric monitors Lambda concurrent executions"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.hello_world.function_name
  }

  tags = merge(
    {
      Name        = "${var.function_name}-concurrent-executions"
      Environment = var.environment
    },
    var.tags
  )
}
