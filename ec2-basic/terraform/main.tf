terraform {
  backend "s3" {
    region = "eu-central-1"
    key    = "s3folder/infra-components-state.tfstate"
  }
}

provider "aws" {
  region     = "eu-central-1"
}

resource "aws_instance" "myec2" {
   ami = "ami-09439f09c55136ecf"
   instance_type = var.basic_ec2_type
}
