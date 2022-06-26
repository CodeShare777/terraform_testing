terraform {
  backend "s3" {
    region = "eu-central-1"
    key    = "s3folder/infra-components-state.tfstate"
  }
}

provider "aws" {
  region     = "eu-central-1"
}

module "ec2-module" {
  source = "./modules/ec2-module"
  basic_ec2_type = var.central_ec2_type
}
