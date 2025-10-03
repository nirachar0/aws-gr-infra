
variable "email" {
  description = "Email address to subscribe to the SNS topic"
  type        = string
  default = "newkaup@gmail.com"
}

variable "lambda_function_name" {
  description = "Name for the Lambda function"
  type        = string
  default     = "guardrails_event_lambda"
}

variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.11"
}

variable "lambda_handler" {
  description = "Lambda handler"
  type        = string
  default     = "handler.lambda_handler"
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 10
}
