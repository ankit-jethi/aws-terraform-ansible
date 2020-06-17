variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "The AWS region you want to deploy your infrastructure to."
}

variable "aws_profile" {
  type        = string
  description = "The name of your AWS profile."
}

variable "vpc_cidr_block" {
  type        = string
  default     = "192.168.0.0/16"
  description = "The CIDR block for the VPC."
}

data "aws_availability_zones" "available" {
  state = "available"
}

variable "subnet_cidr_block" {
  type = map(string)
  default = {
    wp_public1_subnet  = "192.168.10.0/24"
    wp_public2_subnet  = "192.168.20.0/24"
    wp_private1_subnet = "192.168.30.0/24"
    wp_private2_subnet = "192.168.40.0/24"
    wp_rds1_subnet     = "192.168.50.0/24"
    wp_rds2_subnet     = "192.168.60.0/24"
    wp_rds3_subnet     = "192.168.70.0/24"
  }
  description = "The CIDR blocks for the subnets."
}

variable "my_ip" {
  type        = string
  description = "Your Public IP address - For the Dev/Bastion instance security group."
}

variable "domain_name" {
  type        = string
  description = "Your domain name."
}

variable "db_instance_class" {
  type        = string
  default     = "db.t2.micro"
  description = "The instance type to use for the database."
}

variable "db_instance_name" {
  type        = string
  description = "The name for the database instance."
}

variable "db_name" {
  type        = string
  description = "The name for the database."
}

variable "db_username" {
  type        = string
  description = "The username for the database."
}

variable "db_password" {
  type        = string
  description = "The password for the database."
}

variable "key_name" {
  type        = string
  description = "The key name to associate with your instances."
}

variable "path_to_public_key" {
  type        = string
  description = "The path to the public key to associate with your instances."
}

variable "dev_ami" {
  type        = string
  default     = "ami-085925f297f89fce1"
  description = "The AMI to use for the Dev/Bastion instance. Default - Ubuntu Server 18.04 LTS."
}

variable "dev_instance_type" {
  type        = string
  default     = "t2.micro"
  description = "The instance type to use for the Dev/Bastion instance."
}

variable "health_check_interval" {
  type        = string
  default     = "30"
  description = "The amount of time (in seconds) between health checks of an individual target."
}

variable "health_check_path" {
  type        = string
  default     = "/"
  description = "The destination for the health check request."
}

variable "health_check_timeout" {
  type        = string
  default     = "3"
  description = "The amount of time (in seconds) during which no response means a failed health check. Range is 2 to 120 seconds."
}

variable "healthy_threshold" {
  type        = string
  default     = "2"
  description = "The number of consecutive health checks successes required before considering an unhealthy target healthy."
}

variable "unhealthy_threshold" {
  type        = string
  default     = "2"
  description = "The number of consecutive health check failures required before considering the target unhealthy."
}

variable "health_check_matcher" {
  type        = string
  default     = "200-302"
  description = "The HTTP codes to use when checking for a successful response from a target."
}

variable "lc_instance_type" {
  type        = string
  default     = "t2.micro"
  description = "The instance type to use for the Launch Configuration."
}

variable "asg_max_size" {
  type        = string
  description = "The maximum size of the Auto Scaling group."
}

variable "asg_min_size" {
  type        = string
  description = "The minimum size of the Auto Scaling group."
}

variable "asg_grace_period" {
  type        = string
  default     = "300"
  description = "Time (in seconds) after instance comes into service before checking health."
}

variable "asg_check_type" {
  type        = string
  default     = "ELB"
  description = "Controls how health checking is done. EC2 or ELB."
}

variable "asg_desired_capacity" {
  type        = string
  description = "The number of EC2 instances that should be running in the group."
}

variable "delegation_set_id" {
  type        = string
  description = "The id of your Route 53 delegation set for use with the Public Hosted Zone."
}

variable "php_version" {
  type        = string
  default     = "7.2"
  description = "The php version to use for WordPress."
}

