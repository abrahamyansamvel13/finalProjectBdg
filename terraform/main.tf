terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "gaming-stats-tfstate-4ada4094"
    key            = "terraform/state"
    region         = "eu-north-1"
    dynamodb_table = "gaming-stats-terraform-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = "eu-north-1"
}

variable "key_name" {
  type    = string
  default = "gaming-stats-new"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_username" {
  type    = string
  default = "gaming_admin"
}

variable "db_name" {
  type    = string
  default = "gaming_stats"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "gaming-stats-vpc", Project = "gaming-stats-api" }
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-north-1a"
  map_public_ip_on_launch = true
  tags = { Name = "gaming-stats-public-subnet-1", Project = "gaming-stats-api" }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.5.0/24"
  availability_zone       = "eu-north-1b"
  map_public_ip_on_launch = true
  tags = { Name = "gaming-stats-public-subnet-2", Project = "gaming-stats-api" }
}

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-north-1b"
  tags = { Name = "gaming-stats-private-subnet-1", Project = "gaming-stats-api" }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-north-1c"
  tags = { Name = "gaming-stats-private-subnet-2", Project = "gaming-stats-api" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "gaming-stats-igw", Project = "gaming-stats-api" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "gaming-stats-public-rt", Project = "gaming-stats-api" }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "gaming-stats-private-rt", Project = "gaming-stats-api" }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "alb_sg" {
  name        = "gaming-stats-alb-sg"
  description = "Allow HTTP inbound from internet"
  vpc_id      = aws_vpc.main.id
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "gaming-stats-alb-sg", Project = "gaming-stats-api" }
}

resource "aws_security_group" "app_sg" {
  name        = "gaming-stats-app-sg"
  description = "Allow HTTP from ALB and SSH"
  vpc_id      = aws_vpc.main.id
  ingress {
    description     = "HTTP from ALB only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "gaming-stats-app-sg", Project = "gaming-stats-api" }
}

resource "aws_security_group" "db_sg" {
  name        = "gaming-stats-db-sg"
  description = "Allow PostgreSQL only from app_sg"
  vpc_id      = aws_vpc.main.id
  ingress {
    description     = "PostgreSQL from app"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "gaming-stats-db-sg", Project = "gaming-stats-api" }
}

resource "aws_db_subnet_group" "main" {
  name       = "gaming-stats-db-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  tags = { Name = "gaming-stats-db-subnet-group", Project = "gaming-stats-api" }
}

resource "aws_db_instance" "main" {
  identifier        = "gaming-stats-db"
  engine            = "postgres"
  engine_version    = "15"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  db_name           = var.db_name
  username          = var.db_username
  password          = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
  tags = { Name = "gaming-stats-rds", Project = "gaming-stats-api" }
}

resource "aws_lb" "main" {
  name               = "gaming-stats-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  tags = { Name = "gaming-stats-alb", Project = "gaming-stats-api" }
}

resource "aws_lb_target_group" "main" {
  name     = "gaming-stats-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path                = "/health"
    port                = "80"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
  tags = { Name = "gaming-stats-tg", Project = "gaming-stats-api" }
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

resource "aws_launch_template" "app" {
  name_prefix            = "gaming-stats-"
  image_id               = "ami-0989fb15ce71ba39e"
  instance_type          = "t3.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update -y
    curl -fsSL https://get.docker.com | sh
    systemctl start docker
    systemctl enable docker
    apt-get install -y git docker-compose-plugin
    cd /home/ubuntu
    git clone https://github.com/abrahamyansamvel13/finalProjectBdg.git
    cd finalProjectBdg
    echo "DATABASE_URL=postgresql+psycopg2://${var.db_username}:${var.db_password}@${aws_db_instance.main.endpoint}/${var.db_name}" > .env
    docker compose up -d --build
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = { Name = "gaming-stats-asg-instance", Project = "gaming-stats-api" }
  }
  tags = { Name = "gaming-stats-launch-template", Project = "gaming-stats-api" }
}

resource "aws_autoscaling_group" "main" {
  name                = "gaming-stats-asg"
  min_size            = 2
  max_size            = 4
  desired_capacity    = 2
  vpc_zone_identifier = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  target_group_arns   = [aws_lb_target_group.main.arn]
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
  health_check_type         = "ELB"
  health_check_grace_period = 300
  tag {
    key                 = "Name"
    value               = "gaming-stats-asg-instance"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "cpu" {
  name                   = "gaming-stats-cpu-policy"
  autoscaling_group_name = aws_autoscaling_group.main.name
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "app_url" {
  value = "http://${aws_lb.main.dns_name}"
}

output "rds_endpoint" {
  value = aws_db_instance.main.endpoint
}

output "vpc_id" {
  value = aws_vpc.main.id
}
