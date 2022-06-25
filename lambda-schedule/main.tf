terraform {
  backend "s3" {
    region = "eu-central-1"
    key    = "s3folder/infra-components-state.tfstate"
  }
}

provider "aws" {
  region     = "eu-central-1"
}

variable "lambda_function_name" {
  default = "scheduler-lambda"
}

data "archive_file" "lambda_my_function" {
  type             = "zip"
  source_file      = "${path.module}/lambda/scheduled.py"
  output_file_mode = "0666"
  output_path      = "${path.module}/lambda/lambda_function_payload.zip"
}

resource "aws_lambda_function" "test_lambda" {
  function_name = var.lambda_function_name
  filename      = "${path.module}/lambda/lambda_function_payload.zip"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "scheduled.lambda_handler"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = filebase64sha256("lambda/lambda_function_payload.zip")

  runtime = "python3.8"

  environment {
    variables = {
      foo = "bar"
    }
  }
  # ... other configuration ...
  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.log_grouping,
  ]
}

resource "aws_cloudwatch_event_rule" "every_five_minutes_rule" {
    name = "every-five-minutes"
    description = "Fires every five minutes"
    schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "check_lambda_every_five_minutes" {
    rule = aws_cloudwatch_event_rule.every_five_minutes_rule.name
    target_id = "test_lambda"
    arn = aws_lambda_function.test_lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_test_lambda" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.test_lambda.function_name
    principal = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.every_five_minutes_rule.arn
}
