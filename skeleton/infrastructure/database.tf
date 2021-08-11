resource "aws_rds_cluster_instance" "rds_cluster_instances" {
  count                        = lookup(var.rds_cluster_size, terraform.workspace)
  identifier                   = "${var.service_name}-${terraform.workspace}-${var.aws_region}-${count.index}"
  cluster_identifier           = aws_rds_cluster.database_cluster.id
  instance_class               = var.instance_class
  engine                       = var.database_engine
  engine_version               = var.database_engine_version
  auto_minor_version_upgrade   = true
  preferred_maintenance_window = lookup(var.database_maintenance_window, terraform.workspace)

  lifecycle {
    ignore_changes = [
      engine_version,
    ]
  }
}

resource "random_string" "database_cluster_main_password" {
  length  = 64
  special = false
}

resource "random_string" "database_cluster_main_username_suffix" {
  length  = 8
  special = false
}

resource "aws_rds_cluster" "database_cluster" {
  cluster_identifier = "${var.service_name}-${terraform.workspace}-${var.aws_region}"

  availability_zones = [
    "eu-west-1a",
    "eu-west-1b",
    "eu-west-1c",
  ]

  database_name             = "${replace(var.service_name, "-", "_")}_${terraform.workspace}"
  master_username           = "${var.db_username_prefix}${random_string.database_cluster_main_username_suffix.result}"
  master_password           = random_string.database_cluster_main_password.result
  final_snapshot_identifier = "${var.service_name}-${terraform.workspace}-${var.aws_region}-final"
  backup_retention_period   = 30
  preferred_backup_window   = "04:00-06:00"

  vpc_security_group_ids = [
    aws_security_group.database_security_group.id,
  ]

  db_subnet_group_name = lookup(var.db_subnet_group_name, terraform.workspace)
  engine               = var.database_engine
  engine_version       = var.database_engine_version

  lifecycle {
    ignore_changes = [
      engine_version,
    ]
  }
}

resource "aws_security_group" "database_security_group" {
  name        = "${var.service_name}-database-${terraform.workspace}-sg"
  description = "Allow all inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "TCP"

    cidr_blocks = var.ingress_cidr_blocks
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }
}

output "database_endpoint" {
  value = aws_rds_cluster.database_cluster.endpoint
}

output "database_reader_endpoint" {
  value = aws_rds_cluster.database_cluster.reader_endpoint
}

output "database_port" {
  value = aws_rds_cluster.database_cluster.port
}

output "database_name" {
  value = aws_rds_cluster.database_cluster.database_name
}

output "database_main_user" {
  value = "${var.db_username_prefix}${random_string.database_cluster_main_username_suffix.result}"
}

output "database_main_password" {
  value = random_string.database_cluster_main_password.result
}
