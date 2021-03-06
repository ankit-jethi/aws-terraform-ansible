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

# Role Policy

resource "aws_iam_role_policy" "s3_access_policy" {
  name = "s3_access_policy"
  role = aws_iam_role.s3_access_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "${aws_s3_bucket.wp_s3_bucket.arn}",
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

# Elastic IP

resource "aws_eip" "wp_ngw_eip" {
  vpc              = true
  public_ipv4_pool = "amazon"

  tags = {
    Name = "wp_ngw_eip"
  }

  depends_on = [aws_internet_gateway.wp_igw]
}

# NAT Gateway

resource "aws_nat_gateway" "wp_ngw" {
  allocation_id = aws_eip.wp_ngw_eip.id
  subnet_id     = aws_subnet.wp_public2_subnet.id

  tags = {
    Name = "wp_ngw"
  }

  depends_on = [aws_internet_gateway.wp_igw]
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

# Private Route Table - Main

resource "aws_default_route_table" "wp_private_rt" {
  default_route_table_id = aws_vpc.wp_vpc.default_route_table_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.wp_ngw.id
  }

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

# Private Security Group

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

resource "aws_s3_bucket" "wp_s3_bucket" {
  bucket_prefix = "${var.domain_name}-"
  force_destroy = true

  tags = {
    Name = "wp_s3_bucket"
  }
}

#---------------RDS----------------

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

#-------------EC2----------------

# Key Pair

resource "aws_key_pair" "wp_key_pair" {
  key_name   = var.key_name
  public_key = file(var.path_to_public_key)
}

# Dev/Bastion Instance

resource "aws_instance" "wp_dev" {
  ami                    = var.dev_ami
  instance_type          = var.dev_instance_type
  key_name               = aws_key_pair.wp_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.wp_dev_sg.id]
  subnet_id              = aws_subnet.wp_public2_subnet.id
  iam_instance_profile   = aws_iam_instance_profile.s3_access_profile.name

  tags = {
    Name = "wp_dev"
  }

  # Setup the hosts file for ansible

  provisioner "local-exec" {
    command = <<EOD
cat > aws_hosts <<EOF
[dev]
${aws_instance.wp_dev.public_ip}
[dev:vars]
s3bucket=${aws_s3_bucket.wp_s3_bucket.id}
domain=dev.${var.domain_name}
php_version=${var.php_version}
EOF
EOD
  }

  # Run the ansible playbook

  provisioner "local-exec" {
    command = "aws ec2 wait instance-status-ok --instance-ids ${aws_instance.wp_dev.id} --profile ${var.aws_profile} && ansible-playbook -i aws_hosts wordpress.yml"
  }
}

# Load Balancer

resource "aws_lb" "wp_elb" {
  name               = "wp-elb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.wp_elb_sg.id]
  subnets            = [aws_subnet.wp_public1_subnet.id, aws_subnet.wp_public2_subnet.id]
  idle_timeout       = 400
}

# Load Balancer Target Group

resource "aws_lb_target_group" "wp_elb_tg" {
  name                          = "wp-elb-tg"
  port                          = 80
  protocol                      = "HTTP"
  vpc_id                        = aws_vpc.wp_vpc.id
  deregistration_delay          = 400
  load_balancing_algorithm_type = "least_outstanding_requests"

  health_check {
    interval            = var.health_check_interval
    path                = var.health_check_path
    timeout             = var.health_check_timeout
    healthy_threshold   = var.healthy_threshold
    unhealthy_threshold = var.unhealthy_threshold
    matcher             = var.health_check_matcher
  }

  tags = {
    Name = "wp-elb-tg"
  }
}

# Load Balancer Listener

resource "aws_lb_listener" "wp_elb_listener" {
  load_balancer_arn = aws_lb.wp_elb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wp_elb_tg.arn
  }
}

# Generate Random ID for AMI Name

resource "random_id" "golden_ami" {
  byte_length = 8
}

# Create AMI from Dev/Bastion Instance

resource "aws_ami_from_instance" "wp_golden_ami" {
  name               = "wp_ami-${random_id.golden_ami.dec}"
  source_instance_id = aws_instance.wp_dev.id

  provisioner "local-exec" {
    command = <<EOD
cat > userdata <<EOF
#!/bin/bash
aws s3 sync s3://${aws_s3_bucket.wp_s3_bucket.id}/ /var/www/html/
echo '*/5 * * * * aws s3 sync s3://${aws_s3_bucket.wp_s3_bucket.id}/ /var/www/html/' > /root/mycron
crontab /root/mycron
sed -i.bkp 's/dev.${var.domain_name}/www.${var.domain_name}/' /etc/nginx/sites-available/blog.example.com.conf
systemctl reload nginx
EOF
EOD    
  }
}

# Launch Configuration

resource "aws_launch_configuration" "wp_lc" {
  name_prefix          = "wp_lc-"
  image_id             = aws_ami_from_instance.wp_golden_ami.id
  instance_type        = var.lc_instance_type
  iam_instance_profile = aws_iam_instance_profile.s3_access_profile.name
  key_name             = aws_key_pair.wp_key_pair.key_name
  security_groups      = [aws_security_group.wp_private_sg.id]
  user_data            = file("userdata")

  lifecycle {
    create_before_destroy = true
  }
}

# Autoscaling Group

resource "aws_autoscaling_group" "wp_asg" {
  name_prefix               = "wp_asg-"
  max_size                  = var.asg_max_size
  min_size                  = var.asg_min_size
  launch_configuration      = aws_launch_configuration.wp_lc.name
  health_check_grace_period = var.asg_grace_period
  health_check_type         = var.asg_check_type
  desired_capacity          = var.asg_desired_capacity
  force_delete              = true
  vpc_zone_identifier       = [aws_subnet.wp_private1_subnet.id, aws_subnet.wp_private2_subnet.id]
  target_group_arns         = [aws_lb_target_group.wp_elb_tg.arn]

  tag {
    key                 = "Name"
    value               = "wp_asg_instance"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

#----------Route 53-----------------

# Public Zone 

resource "aws_route53_zone" "wp_public_zone" {
  name              = var.domain_name
  delegation_set_id = var.delegation_set_id
  force_destroy     = true
}

# Load Balancer Record

resource "aws_route53_record" "wp_elb_record" {
  zone_id = aws_route53_zone.wp_public_zone.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.wp_elb.dns_name
    zone_id                = aws_lb.wp_elb.zone_id
    evaluate_target_health = false
  }
}

# Dev/Bastion Instance Record

resource "aws_route53_record" "wp_dev_record" {
  zone_id = aws_route53_zone.wp_public_zone.zone_id
  name    = "dev.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.wp_dev.public_ip]
}

# Private Zone

resource "aws_route53_zone" "wp_private_zone" {
  name          = var.domain_name
  force_destroy = true

  vpc {
    vpc_id = aws_vpc.wp_vpc.id
  }
}

# Database Instance Record

resource "aws_route53_record" "wp_db_record" {
  zone_id = aws_route53_zone.wp_private_zone.zone_id
  name    = "db.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_db_instance.wp_db_instance.address]
}

