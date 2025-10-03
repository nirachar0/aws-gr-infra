locals {
  raw_json_content = file("${path.module}/event.json")
  event_pattern = jsondecode(local.raw_json_content)
}

resource "aws_sns_topic" "gr_sns_notifications" {
  name = "gr-sns-notifications"
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.gr_sns_notifications.arn
  protocol  = "email"
  endpoint  = var.email
}


resource "aws_iam_role" "lambda_exec" {
  name = "${var.lambda_function_name}-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_publish_sns" {
  name = "${var.lambda_function_name}-sns-publish"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["sns:Publish"],
        Resource = [aws_sns_topic.gr_sns_notifications.arn]
      }
    ]
  })
}

resource "aws_lambda_function" "handler" {
  function_name = var.lambda_function_name
  filename      = "${path.module}/lambda/${var.lambda_function_name}.zip"
  handler       = var.lambda_handler
  runtime       = var.lambda_runtime
  role          = aws_iam_role.lambda_exec.arn
  timeout       = var.lambda_timeout
  source_code_hash = filebase64sha256("${path.module}/lambda/${var.lambda_function_name}.zip")
  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.gr_sns_notifications.arn
    }
  }
}

resource "aws_cloudwatch_event_rule" "from_cloudtrail" {
  name        = "${var.lambda_function_name}-from-cloudtrail"
  description = "Rule to catch CloudTrail events and send to lambda"
  event_pattern = jsonencode(local.event_pattern)
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.from_cloudtrail.name
  target_id = "lambda"
  arn       = aws_lambda_function.handler.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.handler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.from_cloudtrail.arn
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda/${var.lambda_function_name}.zip"

  source_dir  = "${path.module}/lambda/src"
}
