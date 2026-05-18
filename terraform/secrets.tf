# ─────────────────────────────────────────
# SECRETS MANAGER
# ─────────────────────────────────────────

# Store DB credentials in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "gaming-stats/db-credentials"
  description             = "RDS PostgreSQL credentials for Gaming Stats API"
  recovery_window_in_days = 0 # Allow immediate deletion (for dev/test)

  tags = {
    Name    = "gaming-stats-db-credentials"
    Project = "gaming-stats-api"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    dbname   = var.db_name
    host     = aws_db_instance.main.address
    port     = 5432
  })
}

# ─────────────────────────────────────────
# IAM ROLE FOR EC2
# ─────────────────────────────────────────

# IAM Role — allows EC2 to assume this role
resource "aws_iam_role" "ec2_role" {
  name = "gaming-stats-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name    = "gaming-stats-ec2-role"
    Project = "gaming-stats-api"
  }
}

# Policy — EC2 can only read this specific secret
resource "aws_iam_role_policy" "secrets_policy" {
  name = "gaming-stats-secrets-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Resource = aws_secretsmanager_secret.db_credentials.arn
    }]
  })
}

# Instance Profile — attaches IAM role to EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "gaming-stats-ec2-profile"
  role = aws_iam_role.ec2_role.name
}
