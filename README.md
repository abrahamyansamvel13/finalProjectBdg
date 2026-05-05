# Gaming Stats API

A production-grade REST API for tracking gaming statistics. Built with FastAPI and deployed on AWS with full Infrastructure as Code, auto-scaling, and zero single points of failure.

**Live URL:** `http://gaming-stats-alb-1824775883.eu-north-1.elb.amazonaws.com`

---

## ⚡ Quick Run Guide

Pick your scenario and copy-paste the commands.

### Run locally (fastest, no Docker, no AWS)
```bash
git clone https://github.com/abrahamyansamvel13/finalProjectBdg.git
cd finalProjectBdg
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
DATABASE_URL="sqlite:///./dev.db" uvicorn app.main:app --reload
# open http://localhost:8000/docs
```

### Run locally with Docker
```bash
git clone https://github.com/abrahamyansamvel13/finalProjectBdg.git
cd finalProjectBdg
echo "DATABASE_URL=sqlite:///./dev.db" > .env
docker compose up -d --build
# open http://localhost/docs
```

### Deploy to AWS (production)
```bash
cd terraform
terraform init
terraform apply          # enter your db_password when asked
# open http://<alb_dns_name from output>
```

### Stop everything (save AWS costs)
```bash
aws ec2 stop-instances --instance-ids <id> --region eu-north-1
aws rds stop-db-instance --db-instance-identifier gaming-stats-db --region eu-north-1
```

### Destroy all AWS resources
```bash
cd terraform && terraform destroy
```

---

## Stack

| Layer | Technology |
|-------|-----------|
| Backend | FastAPI, SQLAlchemy 2.0, Pydantic v2 |
| Database | PostgreSQL 15 (AWS RDS) / SQLite (local dev) |
| Server | Uvicorn + Nginx reverse proxy |
| Containers | Docker, Docker Compose |
| Infrastructure | Terraform (IaC) |
| Cloud | AWS EC2, RDS, ALB, ASG, VPC, S3 |
| Automation | Ansible |
| Testing | pytest, httpx |

---

## Architecture

```
Internet
    ↓
Application Load Balancer (ALB)
— distributes traffic across EC2 instances
— health checks via /health endpoint
    ↓               ↓
EC2 #1           EC2 #2          ← Auto Scaling Group (min=2, max=4)
eu-north-1a      eu-north-1b     ← Multi-AZ for high availability
    ↓               ↓
        RDS PostgreSQL
        (private subnet, not accessible from internet)
```

**Key design decisions:**
- ALB eliminates single point of failure — if one EC2 goes down, traffic automatically routes to the other
- ASG automatically adds EC2 instances when CPU > 50%, removes them when load drops
- RDS in private subnet — only reachable from app security group, never from internet
- S3 remote state — Terraform state stored in S3 with DynamoDB locking for team safety

---

## Project Structure

```
finalProjectBdg/
├── app/
│   ├── main.py              # API routes
│   ├── models.py            # SQLAlchemy + Pydantic models
│   └── __init__.py
├── tests/
│   ├── test_main.py         # API tests (in-memory SQLite)
│   └── __init__.py
├── terraform/
│   ├── main.tf              # All AWS infrastructure as code
│   └── terraform.tfvars     # DB credentials (never commit this)
├── terraform-backend/
│   └── main.tf              # S3 bucket + DynamoDB for remote state
├── index.html               # Frontend dashboard
├── nginx.conf               # Reverse proxy config
├── docker-compose.yml       # Local development stack
├── Dockerfile               # App container build
├── entrypoint.sh            # Container startup script
├── inventory.yml            # Ansible hosts
├── ansible-ping.sh          # Ansible infrastructure checks
└── requirements.txt
```

---

## Getting Started

### Option 1 — Local Development (SQLite, no AWS needed)

```bash
git clone https://github.com/abrahamyansamvel13/finalProjectBdg.git
cd finalProjectBdg

python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Terminal 1 — start backend
DATABASE_URL="sqlite:///./dev.db" uvicorn app.main:app --reload

# Terminal 2 — start frontend
python3 -m http.server 9000
```

| Service | URL |
|---------|-----|
| Frontend dashboard | http://localhost:9000/index.html |
| API | http://localhost:8000 |
| Interactive API docs | http://localhost:8000/docs |

### Option 2 — Docker (local, with .env file)

Create a `.env` file first:
```bash
echo "DATABASE_URL=sqlite:///./dev.db" > .env
```

Then run:
```bash
docker compose up -d --build
```

| Service | URL |
|---------|-----|
| API via Nginx | http://localhost |
| API docs | http://localhost/docs |
| Health check | http://localhost/health |

### Option 3 — AWS (production)

See the [Infrastructure](#infrastructure) section below.

---

## API Reference

### Endpoints

| Method | Endpoint | Description | Status Code |
|--------|----------|-------------|-------------|
| GET | `/health` | Health check | 200 |
| GET | `/stats` | Get all records | 200 |
| POST | `/stats` | Create a record | 201 |
| GET | `/stats/{id}` | Get record by ID | 200 / 404 |
| PUT | `/stats/{id}` | Partial update | 200 / 404 |
| DELETE | `/stats/{id}` | Delete record | 200 / 404 |
| GET | `/stats/player/{player_id}` | All records for a player | 200 |
| GET | `/stats/game/{game_name}` | All records for a game | 200 |

> **Note:** Routes `/stats/player/` and `/stats/game/` are declared **before** `/stats/{id}` in the code — this is intentional to prevent FastAPI from treating "player" or "game" as an integer ID.

### Data Model

```json
{
  "game_name": "Chess",
  "player_id": "player123",
  "score": 1500,
  "level": 10,
  "play_time_minutes": 45,
  "timestamp": "2026-04-10T13:00:00Z"
}
```

`level`, `play_time_minutes`, and `timestamp` are optional. For PUT requests, all fields are optional — only send what you want to update.

### Examples

```bash
# Health check
curl http://localhost/health

# Create a record
curl -X POST http://localhost/stats \
  -H "Content-Type: application/json" \
  -d '{"game_name": "Chess", "player_id": "player123", "score": 1500, "level": 10}'

# Get all records for a player
curl http://localhost/stats/player/player123

# Get all records for a game
curl http://localhost/stats/game/Chess

# Partial update — only update score
curl -X PUT http://localhost/stats/1 \
  -H "Content-Type: application/json" \
  -d '{"score": 2000}'

# Delete a record
curl -X DELETE http://localhost/stats/1
```

---

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | Full DB connection string | `postgresql+psycopg2://user:pass@host:5432/db` |

For local SQLite development:
```bash
DATABASE_URL="sqlite:///./dev.db"
```

For AWS RDS PostgreSQL (set automatically by Terraform in production):
```bash
DATABASE_URL="postgresql+psycopg2://gaming_admin:password@gaming-stats-db.xxx.eu-north-1.rds.amazonaws.com:5432/gaming_stats"
```

---

## Infrastructure

All AWS infrastructure is managed with Terraform as code. No manual "ClickOps" required.

### AWS Resources

| Resource | Details |
|----------|---------|
| VPC | `10.0.0.0/16`, DNS enabled |
| Public Subnet 1 | `10.0.1.0/24`, eu-north-1a |
| Public Subnet 2 | `10.0.5.0/24`, eu-north-1b |
| Private Subnet 1 | `10.0.2.0/24`, eu-north-1b |
| Private Subnet 2 | `10.0.3.0/24`, eu-north-1c |
| Internet Gateway | Attached to VPC |
| ALB | Internet-facing, spans both public subnets |
| Target Group | Health check on `/health`, port 80 |
| Launch Template | Ubuntu 22.04, t3.micro, auto-installs Docker |
| Auto Scaling Group | min=2, max=4, desired=2 |
| Scaling Policy | TargetTracking CPU 50% |
| RDS PostgreSQL | db.t3.micro, 20GB, private subnet |
| S3 Bucket | Remote Terraform state with versioning |
| DynamoDB Table | State locking |

### Security Groups

```
Internet → alb_sg (port 80) → app_sg (port 80 from ALB only) → db_sg (port 5432 from app_sg only)
```

- `alb_sg` — accepts HTTP from internet
- `app_sg` — accepts HTTP only from ALB, SSH from anywhere
- `db_sg` — accepts PostgreSQL only from app_sg (database never exposed to internet)

### Deploy from scratch

**Prerequisites:** AWS CLI configured, Terraform installed

```bash
# Step 1 — create S3 remote state backend (one time only)
cd terraform-backend
terraform init
terraform apply
# note the bucket_name from output

# Step 2 — set your DB password
cd ../terraform
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # set db_password

# Step 3 — deploy everything
terraform init
terraform plan
terraform apply
# output will show: alb_dns_name = "gaming-stats-alb-xxx.eu-north-1.elb.amazonaws.com"
```

### Manage infrastructure

```bash
# See current state
terraform show

# Stop EC2 instances (save costs, keep infrastructure)
aws ec2 stop-instances --instance-ids <id> --region eu-north-1
aws rds stop-db-instance --db-instance-identifier gaming-stats-db --region eu-north-1

# Destroy everything
terraform destroy
```

> ⚠️ Never commit `terraform.tfvars` — it contains your DB password. It is in `.gitignore`.

---

## Testing

Tests use an in-memory SQLite database — no setup needed, no files left behind.

```bash
source venv/bin/activate
pytest tests/ -v
```

Tests cover: create, read, update, delete, filter by player, filter by game, 404 handling.

---

## Ansible

Ansible checks container health without SSH — uses `ansible_connection=docker` to connect natively.

```bash
sudo apt install -y ansible

chmod +x ansible-ping.sh
sudo ./ansible-ping.sh
```

Expected output:
```
>>> [1/3] Pinging backend (FastAPI)...
gaming_stats_api | SUCCESS => { "ping": "pong" }

>>> [2/3] Pinging database via raw...
mysqld is alive — pong

>>> [3/3] Pinging proxy (Nginx) via raw...
nginx: configuration file test is successful — pong
```

| Container | Ansible module | Reason |
|-----------|---------------|--------|
| `gaming_stats_api` | `ping` + `shell` | Has Python 3.11 |
| `gaming_stats_db` | `raw` | Alpine — no Python |
| `gaming_stats_nginx` | `raw` | Alpine — no Python |

---

## Troubleshooting

**Port already in use (local):**
```bash
fuser -k 8000/tcp
fuser -k 9000/tcp
```

**Docker permission denied:**
```bash
sudo usermod -aG docker $USER
# log out and back in
```

**Terraform state locked:**
```bash
terraform force-unlock <lock-id>
# or manually:
aws dynamodb delete-item \
  --table-name gaming-stats-terraform-lock \
  --key '{"LockID": {"S": "gaming-stats-tfstate-xxx/terraform/state"}}' \
  --region eu-north-1
```

**ALB returning 502:**
```bash
# Check if ASG instances are healthy
aws elbv2 describe-target-health \
  --target-group-arn <arn> \
  --region eu-north-1

# SSH into an instance and check logs
ssh -i ~/gaming-stats-new.pem ubuntu@<ec2-ip>
sudo docker logs gaming_stats_api
```

**RDS connection refused:**
- RDS is in a private subnet — only reachable from EC2 inside the VPC
- Connect via EC2 as a jump host, never directly from your machine
