terraform {
  required_version = "0.13.0"
  backend "s3" {
    bucket         = "terraform-state-storage-${var.account_id}"
    dynamodb_table = "terraform-state-lock-${var.account_id}"
    key            = "ruby-example/app.tfstate"
    region         = "us-west-2"
  }
}

provider "aws" {
  version = ">= 3.0"
  region  = "us-west-2"
}

variable "image_tag" {
  type = string
}

variable "account_id" {
  type = string
}

module "app" {
  source                           = "../../modules/app/"
  env                              = "dev"
  image_tag                        = var.image_tag
  codedeploy_termination_wait_time = 0
}

output "url" {
  value = module.app.url
}


module "app" {
  source                           = "../../modules/app/"
  env                              = "dev"
  image_tag                        = var.image_tag
}




