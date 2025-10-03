output "rule_arn" {
  value = aws_cloudwatch_event_rule.from_cloudtrail.arn
}

output "rule_name" {
  value = aws_cloudwatch_event_rule.from_cloudtrail.name
}

output "lambda_arn" {
  value = aws_lambda_function.handler.arn
}

output "lambda_name" {
  value = aws_lambda_function.handler.function_name
}
