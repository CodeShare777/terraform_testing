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

variable "horizontal_api" {
  type = string
  default = "internal_xyz_horizontal"
}

variable "services_list" {
  type = list
  default = [
    {
      lambda_func_name  = "func-internal"
      endpoint_to_probe = "https://google.com"
      spoc_service_name = "internal_xyz_service"
    },
    {
      lambda_func_name  = "func-external"
      endpoint_to_probe = "https://msn.com"
      spoc_service_name = "external_xyz_service"
    },
    {
      lambda_func_name  = "func-idl"
      endpoint_to_probe = "https://idl.com"
      spoc_service_name = "idl_xyz_service"
    }
  ]
}

data "archive_file" "lambda_my_function" {
  type             = "zip"
  source_file      = "${path.module}/lambda/scheduled.py"
  output_file_mode = "0666"
  output_path      = "${path.module}/lambda/lambda_function_payload.zip"
}

resource "aws_lambda_function" "test_lambda" {
  function_name = var.services_list[count.index]["lambda_func_name"]
  filename      = "${path.module}/lambda/lambda_function_payload.zip"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "scheduled.lambda_handler"
  count         = length(var.services_list)

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = filebase64sha256("lambda/lambda_function_payload.zip")

  runtime = "python3.8"

  environment {
    variables = {
      endpoint_to_probe = var.services_list[count.index]["endpoint_to_probe"]
      spoc_service_name = var.services_list[count.index]["spoc_service_name"]
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
  rule      = aws_cloudwatch_event_rule.every_five_minutes_rule.name
  target_id = "test_lambda_${count.index}"
  arn       = aws_lambda_function.test_lambda[count.index].arn
  count     = length(var.services_list)
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_test_lambda" {
  count = length(var.services_list)
  statement_id = "AllowExecutionFromCloudWatch"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_lambda[count.index].function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.every_five_minutes_rule.arn
}
