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

variable "key_name" {}

variable "path_to_public_key" {}

variable "dev_ami" {}

variable "dev_instance_type" {}

variable "health_check_interval" {}

variable "health_check_path" {}

variable "health_check_timeout" {}

variable "healthy_threshold" {}

variable "unhealthy_threshold" {}

variable "health_check_matcher" {}

variable "lc_instance_type" {}

variable "asg_max_size" {}

variable "asg_min_size" {}

variable "asg_grace_period" {}

variable "asg_check_type" {}

variable "asg_desired_capacity" {}

variable "delegation_set_id" {}
