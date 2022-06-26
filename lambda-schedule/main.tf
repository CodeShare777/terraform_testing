terraform {
  backend "s3" {
    region = "eu-central-1"
    key    = "s3folder/infra-components-state.tfstate"
  }
}

provider "aws" {
  region     = "eu-central-1"
}

module "lambda-module" {
  source = "./modules/lambda"
  services_list = var.central_services_list
}
