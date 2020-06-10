variable "aws_region" {}

variable "aws_profile" {}

variable "vpc_cidr_block" {}

data "aws_availability_zones" "available" {
  state = "available"
}

variable "subnet_cidr_block" {
  type = map(string)
}

variable "my_ip" {}

variable "domain_name" {}

variable "db_instance_class" {}

variable "db_instance_name" {}

variable "db_name" {}

variable "db_username" {}

variable "db_password" {}
