variable "env" {
  type = string
}

variable "image_tag" {
  type = string
}

locals {
  name = "simple-ruby-web"
  tags = {
    env              = "${var.env}"
    data-sensitivity = "public"
    repo             = "https://github.com/rayos006/simple-ruby-website"
  }
}

data "aws_ecr_repository" "my_ecr_repo" {
  name = "${local.name}-${var.env}"
}

data "aws_ssm_parameter" "mysql_username" {
  name = "/${local.name}/${var.env}/mysql-username"
}

data "aws_ssm_parameter" "mysql_password" {
  name = "/${local.name}/${var.env}/mysql-password"
  with_decryption = true
}

module "acs" {
  source = "github.com/byu-oit/terraform-aws-acs-info?ref=v3.1.0"
}

# -----------------------------------------------------------------------------
# Fargate
# -----------------------------------------------------------------------------

module "my_fargate_api" {
  source                        = "github.com/byu-oit/terraform-aws-fargate-api?ref=v3.1.2"
  app_name                      = "${local.name}-${var.env}"
  container_port                = 3000
  task_policies = [aws_iam_policy.my_s3_policy.arn]
  security_groups = [aws_security_group.allow_mysql.id]

  hosted_zone                      = module.acs.route53_zone
  https_certificate_arn            = module.acs.certificate.arn
  public_subnet_ids                = module.acs.public_subnet_ids
  private_subnet_ids               = module.acs.private_subnet_ids
  vpc_id                           = module.acs.vpc.id
  codedeploy_service_role_arn      = module.acs.power_builder_role.arn
  role_permissions_boundary_arn    = module.acs.role_permissions_boundary.arn


  tags                             = local.tags

  primary_container_definition = {
    name  = "${local.name}-${var.env}"
    image = "${data.aws_ecr_repository.my_ecr_repo.repository_url}:${var.image_tag}"
    ports = [3000]
    environment_variables = {
      MYSQL_ENDPOINT = aws_rds_cluster.my_rds.endpoint
    }
    secrets = {
      "MYSQL_USERNAME" = "/${local.name}/${var.env}/mysql-username",
      "MYSQL_PASSWORD" = "/${local.name}/${var.env}/mysql-password"
    }
    efs_volume_mounts = null
  }

  autoscaling_config = {
    min_capacity = 1
    max_capacity = 2
  }

  codedeploy_lifecycle_hooks = null
}

# -----------------------------------------------------------------------------
# Fargate
# -----------------------------------------------------------------------------

resource "aws_rds_cluster" "my_rds" {
  cluster_identifier = "${local.name}-${var.env}"
  engine             = "aurora"
  engine_version     = "5.7.12"
  engine_mode        = "serverless"

  scaling_configuration {
    auto_pause               = true
    max_capacity             = 256
    min_capacity             = 2
    seconds_until_auto_pause = 300
    timeout_action           = "ForceApplyCapacityChange"
  }

  storage_encrypted            = true
  final_snapshot_identifier    = "${local.name}-${var.env}"
  skip_final_snapshot          = false
  preferred_maintenance_window = "Sun:01:00-Sun:04:00"
  preferred_backup_window      = "01:00-02:00"
  backup_retention_period      = 5
  deletion_protection          = true
  database_name                = "${local.name}-${var.env}"
  master_username              = data.aws_ssm_parameter.mysql_username
  master_password              = data.aws_ssm_parameter.mysql_password
  db_subnet_group_name         = module.acs.db_subnet_group_name
  vpc_security_group_ids       = [module.acs.rds_security_group.id, aws_security_group.allow_mysql.id]

  tags = local.tags
}

resource "aws_security_group" "allow_mysql" {
  name        = "allow_mysql"
  description = "Allow MYSQL traffic"
  vpc_id      = module.acs.vpc.id
  ingress {
    # TLS (change to whatever ports you need)
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    self      = true
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}