terraform {
  backend "s3" {
    region = "eu-central-1"
    key    = "s3folder/infra-components-state.tfstate"
  }
}

provider "aws" {
  region     = "eu-central-1"
}

data "archive_file" "lambda_my_function" {
  type             = "zip"
  source_file      = "${path.root}/send-spoc-status.py"
  output_file_mode = "0666"
  output_path      = "${path.root}/spoc_lambda_payload.zip"
}

resource "aws_lambda_function" "spoc_lambda" {
  count         = length(var.services_list)
  function_name = var.services_list[count.index]["lambda_func_name"]
  filename      = "${path.root}/spoc_lambda_payload.zip"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "send-spoc-status.lambda_handler"

  source_code_hash = filebase64sha256("${path.root}/spoc_lambda_payload.zip")

  runtime = "python3.8"

  environment {
    variables = {
      APPLICATION_ENDPOINT = var.services_list[count.index]["endpoint_to_probe"]
      SPOC_SERVICE = var.services_list[count.index]["spoc_service_name"]
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.log_grouping,
  ]
}

resource "aws_cloudwatch_event_rule" "every_five_minutes_rule" {
  name                = "every-five-minutes"
  description         = "Fires every five minutes"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "check_lambda_every_five_minutes" {
  count     = length(var.services_list)
  rule      = aws_cloudwatch_event_rule.every_five_minutes_rule.name
  target_id = "spoc_lambda_${count.index}"
  arn       = aws_lambda_function.spoc_lambda[count.index].arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_spoc_lambda" {
  count = length(var.services_list)
  statement_id = "AllowExecutionFromCloudWatch"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.spoc_lambda[count.index].function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.every_five_minutes_rule.arn
}

# This is to optionally manage the CloudWatch Log Group for the Lambda Function.
# If skipping this resource configuration, also add "logs:CreateLogGroup" to the IAM policy below.
resource "aws_cloudwatch_log_group" "log_grouping" {
  count             = length(var.services_list)
  name              = "/aws/lambda/${var.services_list[count.index]["lambda_func_name"]}"
  retention_in_days = 14
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  })
}

# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource": "arn:aws:logs:*:*:*",
        "Effect": "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

