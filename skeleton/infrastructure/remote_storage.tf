provider "aws" {
  region  = var.aws_region
}

terraform {
  backend "s3" {
    bucket = "spring-boot-template-infrastructure-terraform-state"
    key    = "terraform.tfstate"
    region = "eu-west-1"
  }
}

data "terraform_remote_state" "infrastructure" {
  backend   = "s3"
  workspace = terraform.workspace

  config = {
    bucket = "spring-boot-template-infrastructure-terraform-state"
    key    = "terraform.tfstate"
    region = "eu-west-1"
  }
}
