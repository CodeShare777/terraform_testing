variable "basic_ec2_type" {
  default = "t2.micro"
}

variable "lambda_function_name" {
  default = "scheduler-lambda"
}

variable "central_services_list" {
  type = list
  default = []
}
