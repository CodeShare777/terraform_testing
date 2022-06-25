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
  default = "lambda_function_name"
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
