variable "env" {
  type = string
}

locals {
  name = "simple-ruby-web"
}

variable "mysql_password" {
  type = string
}

resource "aws_ssm_parameter" "mysql_username" {
  name  = "/${local.name}/${var.env}/mysql-username"
  type  = "String"
  value = "${local.name}_admin_${var.env}"
}

resource "aws_ssm_parameter" "mysql_password" {
  name  = "/${local.name}/${var.env}/mysql-password"
  type  = "SecureString"
  value = var.mysql_password
}

module "my_ecr" {
  source = "github.com/byu-oit/terraform-aws-ecr?ref=v2.0.1"
  name   = "${local.name}-${var.env}"
}