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

  tags = { Name = "gaming-stats-alb-sg", Project = "gaming-stats-api" }
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

  tags = { Name = "gaming-stats-app-sg", Project = "gaming-stats-api" }
}

# --- Load Balancer ---

resource "aws_lb" "main" {
  name               = "gaming-stats-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnet_ids

  tags = { Name = "gaming-stats-alb", Project = "gaming-stats-api" }
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

  tags = { Name = "gaming-stats-tg", Project = "gaming-stats-api" }
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

# --- Launch Template ---

resource "aws_launch_template" "app" {
  name_prefix   = "gaming-stats-"
  image_id      = "ami-0989fb15ce71ba39e"
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  # Attach IAM role so EC2 can read from Secrets Manager
  iam_instance_profile {
    name = var.iam_instance_profile
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e

    apt-get update -y
    curl -fsSL https://get.docker.com | sh
    systemctl start docker
    systemctl enable docker
    apt-get install -y git docker-compose-plugin awscli python3

    # Fetch credentials from Secrets Manager — no passwords in code
    SECRET=$(aws secretsmanager get-secret-value \
      --secret-id ${var.secret_arn} \
      --region eu-north-1 \
      --query SecretString \
      --output text)

    DB_USERNAME=$(echo $SECRET | python3 -c "import sys,json; print(json.load(sys.stdin)['username'])")
    DB_PASSWORD=$(echo $SECRET | python3 -c "import sys,json; print(json.load(sys.stdin)['password'])")
    DB_NAME=$(echo $SECRET | python3 -c "import sys,json; print(json.load(sys.stdin)['dbname'])")

    cd /home/ubuntu
    git clone https://github.com/abrahamyansamvel13/finalProjectBdg.git
    cd finalProjectBdg

    echo "DATABASE_URL=postgresql+psycopg2://$DB_USERNAME:$DB_PASSWORD@${var.db_endpoint}/$DB_NAME" > .env

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

  tags = { Name = "gaming-stats-launch-template", Project = "gaming-stats-api" }
}

# --- Auto Scaling Group ---

resource "aws_autoscaling_group" "main" {
  name                      = "gaming-stats-asg"
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
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
