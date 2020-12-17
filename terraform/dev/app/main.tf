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

output "codedeploy_app_name" {
  value = module.app.codedeploy_app_name
}

output "codedeploy_deployment_group_name" {
  value = module.app.codedeploy_deployment_group_name
}

output "codedeploy_appspec_json_file" {
  value = module.app.codedeploy_appspec_json_file
}














# -----------------------------------------------------------------------------
# RDS
# -----------------------------------------------------------------------------
resource "aws_db_instance" "mysql" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "foo"
  parameter_group_name = "default.mysql5.7"
}