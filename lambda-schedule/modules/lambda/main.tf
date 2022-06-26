data "archive_file" "lambda_my_function" {
  type             = "zip"
  source_file      = "${path.root}/lambda/scheduled.py"
  output_file_mode = "0666"
  output_path      = "${path.root}/lambda/lambda_function_payload.zip"
}

resource "aws_lambda_function" "test_lambda" {
  function_name = var.services_list[count.index]["lambda_func_name"]
  filename      = "${path.root}/lambda/lambda_function_payload.zip"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "scheduled.lambda_handler"
  count         = length(var.services_list)

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
    # aws_cloudwatch_log_group.log_grouping,
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
