terraform {
  backend "s3" {
    bucket         = "terraform-state-storage-${var.account_id}"
    dynamodb_table = "terraform-state-lock-${var.account_id}"
    key            = "ruby-example/setup.tfstate"
    region         = "us-west-2"
  }
}

provider "aws" {
  version = ">= 3.0"
  region  = "us-west-2"
}

variable "account_id" {
  type = string
}

variable "mysql_password" {
  type = string
}

module "setup" {
  source      = "../../modules/setup/"
  env         = "dev"
  mysql_password = var.mysql_password
}