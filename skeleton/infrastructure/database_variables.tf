variable "rds_cluster_size" {
  description = "RDS Cluster Size"

  default = {
    prod = "1"
    stage = "1"
  }
}
variable "database_maintenance_window" {
  description = "RDS Maintenance Window"
  default = {
    prod = "Wed:09:00-Wed:10:00"
    stage = "Tue:09:00-Tue:10:00"
  }
}

variable "database_engine" {
  description = "Engine type, example values mysql, postgres"
  default = "aurora-postgresql"
}

variable "database_engine_version" {
  description = "RDS Engine version"
  default = "12.4"
}

variable "instance_class" {
  default = "db.t3.medium"
  description = "Instance class"
}

variable "db_username_prefix" {
  default = "jimdo_user_"
  description = "User name"
}

variable "db_subnet_group_name" {
  default = {
    prod = "prod-jimdo"
    stage = "stable-jimdo"
  }
}

variable "subnet_ids" {
  type = map

  default = {
    prod = [
      "subnet-3312b758",
      "subnet-0d12b766",
      "subnet-7c12b717",
    ]

    stage = [
      "subnet-d112b7ba",
      "subnet-771db81c",
      "subnet-4f1db824",
    ]
  }

  description = "CIDRs for RDS Security Group"
}
