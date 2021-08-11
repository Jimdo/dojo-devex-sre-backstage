variable "vpc_id" {
  default = "vpc-3cf6d355"
  description = "Main VPC"
}

variable "aws_region" {
  default = "eu-west-1"
  description = "AWS region"
}

variable "service_name" {
  description = "Name of this service, used to derive various names"
}

variable "ingress_cidr_blocks" {
  type = list
  default = [
    "10.8.0.0/16",
    # wonderland peering
    "10.5.123.0/24",
    # VPN
    "10.100.3.0/24"
  ]
  description = "List of CIDR blocks used for configuring ingress"
}

variable "account_id" {
  description = "AWS account id"
  default = {
    prod = "874814834432"
    stage = "874814834432"
  }
}
