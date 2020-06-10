#------------IAM----------------

# IAM Role for EC2 instances to access S3

resource "aws_iam_role" "s3_access_role" {
  name = "s3_access_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Instance Profile

resource "aws_iam_instance_profile" "s3_access_profile" {
  name = "s3_access_profile"
  role = aws_iam_role.s3_access_role.name
}

# Role Policy - Edit to restrict S3 actions & resource

resource "aws_iam_role_policy" "s3_access_policy" {
  name = "s3_access_policy"
  role = aws_iam_role.s3_access_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.wp_s3_bucket.arn}/*"
      ]
    }
  ]
}
EOF
}

#---------------VPC-----------------

resource "aws_vpc" "wp_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true

  tags = {
    Name = "wp_vpc"
  }

}

# Internet Gateway

resource "aws_internet_gateway" "wp_igw" {
  vpc_id = aws_vpc.wp_vpc.id

  tags = {
    Name = "wp_igw"
  }
}


# Public Route Table

resource "aws_route_table" "wp_public_rt" {
  vpc_id = aws_vpc.wp_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wp_igw.id
  }

  tags = {
    Name = "wp_public_rt"
  }
}

# Private Route Table - Default

resource "aws_default_route_table" "wp_private_rt" {
  default_route_table_id = aws_vpc.wp_vpc.default_route_table_id

  tags = {
    Name = "wp_private_rt"
  }
}

# Public Subnets

resource "aws_subnet" "wp_public1_subnet" {
  vpc_id                  = aws_vpc.wp_vpc.id
  availability_zone       = data.aws_availability_zones.available.names[0]
  cidr_block              = var.subnet_cidr_block["wp_public1_subnet"]
  map_public_ip_on_launch = true

  tags = {
    Name = "wp_public1_subnet"
  }
}

resource "aws_subnet" "wp_public2_subnet" {
  vpc_id                  = aws_vpc.wp_vpc.id
  availability_zone       = data.aws_availability_zones.available.names[1]
  cidr_block              = var.subnet_cidr_block["wp_public2_subnet"]
  map_public_ip_on_launch = true

  tags = {
    Name = "wp_public2_subnet"
  }
}

# Private Subnets

resource "aws_subnet" "wp_private1_subnet" {
  vpc_id            = aws_vpc.wp_vpc.id
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block        = var.subnet_cidr_block["wp_private1_subnet"]

  tags = {
    Name = "wp_private1_subnet"
  }
}

resource "aws_subnet" "wp_private2_subnet" {
  vpc_id            = aws_vpc.wp_vpc.id
  availability_zone = data.aws_availability_zones.available.names[1]
  cidr_block        = var.subnet_cidr_block["wp_private2_subnet"]

  tags = {
    Name = "wp_private2_subnet"
  }
}

# RDS Subnets

resource "aws_subnet" "wp_rds1_subnet" {
  vpc_id            = aws_vpc.wp_vpc.id
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block        = var.subnet_cidr_block["wp_rds1_subnet"]

  tags = {
    Name = "wp_rds1_subnet"
  }
}

resource "aws_subnet" "wp_rds2_subnet" {
  vpc_id            = aws_vpc.wp_vpc.id
  availability_zone = data.aws_availability_zones.available.names[1]
  cidr_block        = var.subnet_cidr_block["wp_rds2_subnet"]

  tags = {
    Name = "wp_rds2_subnet"
  }
}

resource "aws_subnet" "wp_rds3_subnet" {
  vpc_id            = aws_vpc.wp_vpc.id
  availability_zone = data.aws_availability_zones.available.names[2]
  cidr_block        = var.subnet_cidr_block["wp_rds3_subnet"]

  tags = {
    Name = "wp_rds3_subnet"
  }
}

# RDS Subnet Group

resource "aws_db_subnet_group" "wp_rds_subnet_group" {
  name       = "wp_rds_subnet_group"
  subnet_ids = [aws_subnet.wp_rds1_subnet.id, aws_subnet.wp_rds2_subnet.id, aws_subnet.wp_rds3_subnet.id]

  tags = {
    Name = "wp_rds_subnet_group"
  }
}


# Route Table associations

resource "aws_route_table_association" "wp_public1_association" {
  route_table_id = aws_route_table.wp_public_rt.id
  subnet_id      = aws_subnet.wp_public1_subnet.id
}

resource "aws_route_table_association" "wp_public2_association" {
  route_table_id = aws_route_table.wp_public_rt.id
  subnet_id      = aws_subnet.wp_public2_subnet.id
}

# Load Balancer Security Group

resource "aws_security_group" "wp_elb_sg" {
  name        = "wp_elb_sg"
  description = "Load Balancer Security Group"
  vpc_id      = aws_vpc.wp_vpc.id

  ingress {
    description = "HTTP access from the world"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "wp_elb_sg"
  }
}

# Dev/Bastion Security Group

resource "aws_security_group" "wp_dev_sg" {
  name        = "wp_dev_sg"
  description = "Dev/Bastion Security Group"
  vpc_id      = aws_vpc.wp_vpc.id

  ingress {
    description = "HTTP access from me"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description = "SSH access from me"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "wp_dev_sg"
  }
}

# Private Security Group - Maybe allow all traffic from self?

resource "aws_security_group" "wp_private_sg" {
  name        = "wp_private_sg"
  description = "Private Security Group"
  vpc_id      = aws_vpc.wp_vpc.id

  ingress {
    description     = "HTTP access from the Load Balancer"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.wp_elb_sg.id]
  }

  ingress {
    description     = "SSH access from Dev/Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.wp_dev_sg.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "wp_private_sg"
  }
}

# RDS Security Group

resource "aws_security_group" "wp_rds_sg" {
  name        = "wp_rds_sg"
  description = "RDS Security Group"
  vpc_id      = aws_vpc.wp_vpc.id

  ingress {
    description     = "DB access from Private & Dev/Bastion Security Group"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.wp_private_sg.id, aws_security_group.wp_dev_sg.id]
  }

  tags = {
    Name = "wp_rds_sg"
  }
}

# VPC Endpoint for S3

resource "aws_vpc_endpoint" "wp_vpce_s3" {
  service_name    = "com.amazonaws.${var.aws_region}.s3"
  vpc_id          = aws_vpc.wp_vpc.id
  route_table_ids = [aws_route_table.wp_public_rt.id, aws_default_route_table.wp_private_rt.id]

  tags = {
    Name = "wp_vpce_s3"
  }
}

#-------------S3--------------

# S3 bucket

# resource "random_id" "wp_s3_bucket" {
#   byte_length = 2
# }

resource "aws_s3_bucket" "wp_s3_bucket" {
  bucket_prefix = "${var.domain_name}-"
  force_destroy = true

  tags = {
    Name = "wp_s3_bucket"
  }
}

resource "aws_db_instance" "wp_db_instance" {
  allocated_storage      = 10
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = var.db_instance_class
  identifier             = var.db_instance_name
  name                   = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.wp_rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.wp_rds_sg.id]
  skip_final_snapshot    = true
}
