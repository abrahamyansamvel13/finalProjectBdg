# --- Security Groups ---

resource "aws_security_group" "alb_sg" {
  name        = "gaming-stats-alb-sg"
  description = "Allow HTTP inbound from internet"
  vpc_id      = var.vpc_id

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

  tags = {
    Name    = "gaming-stats-alb-sg"
    Project = "gaming-stats-api"
  }
}

resource "aws_security_group" "app_sg" {
  name        = "gaming-stats-app-sg"
  description = "Allow HTTP from ALB and SSH"
  vpc_id      = var.vpc_id

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

  tags = {
    Name    = "gaming-stats-app-sg"
    Project = "gaming-stats-api"
  }
}

# --- Load Balancer ---

resource "aws_lb" "main" {
  name               = "gaming-stats-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnet_ids

  tags = {
    Name    = "gaming-stats-alb"
    Project = "gaming-stats-api"
  }
}

resource "aws_lb_target_group" "main" {
  name     = "gaming-stats-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

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

  tags = {
    Name    = "gaming-stats-tg"
    Project = "gaming-stats-api"
  }
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# --- Auto Scaling & Launch Template ---

resource "aws_launch_template" "app" {
  name_prefix   = "gaming-stats-"
  image_id      = "ami-0989fb15ce71ba39e" # Твой оригинальный AMI
  instance_type = "t3.micro"
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  # Твой оригинальный скрипт с Docker Compose
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
    echo "DATABASE_URL=postgresql+psycopg2://${var.db_username}:${var.db_password}@${var.db_endpoint}/${var.db_name}" > .env
    docker compose up -d --build
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "gaming-stats-asg-instance"
      Project = "gaming-stats-api"
    }
  }

  tags = {
    Name    = "gaming-stats-launch-template"
    Project = "gaming-stats-api"
  }
}

resource "aws_autoscaling_group" "main" {
  name                      = "gaming-stats-asg"
  min_size                  = 2
  max_size                  = 4
  desired_capacity          = 2
  vpc_zone_identifier       = var.public_subnet_ids
  target_group_arns         = [aws_lb_target_group.main.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

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
