# Gaming Stats API

A FastAPI-based REST API for managing gaming statistics with MySQL database.

## Features

- Create and retrieve gaming statistics
- Filter stats by player or game
- RESTful API endpoints
- MySQL database integration
- Built with FastAPI, Pydantic, and SQLAlchemy
- 🐳 **Docker & Docker Compose support** - Run the entire stack with one command
- 🚀 **Docker Hub integration** - Pre-built images available at `abrahamyan001/gaming-stats-api`
- 🔄 **Optimized multi-stage Docker build** - Minimal image size with pinned dependencies
- 🏥 **Health checks & service orchestration** - Built-in monitoring and proper startup sequencing
- ⚡ **Hot reload** - Auto-restart on code changes during development

## Installation

### Requirements
- Python 3.8+
- Docker (optional, for containerization)
- Docker Compose (optional, for running with MySQL)

### Local Setup

1. Clone the repository
2. Create and activate a virtual environment:
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   ```
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

## Database Setup

1. Install MySQL server on your system
2. Create a database named `gaming_stats`
3. Create a user with appropriate permissions
4. Set the `DATABASE_URL` environment variable:
   ```bash
   export DATABASE_URL="mysql+pymysql://username:password@localhost/gaming_stats"
   ```

For development/testing, the app defaults to SQLite if no DATABASE_URL is set.

## 🚀 Deployment Guide

This guide covers how to run your Gaming Stats API project in different environments.

### Quick Start (Recommended)

The easiest way to run the project anywhere is using Docker:

```bash
# Clone the repository
git clone <your-repo-url>
cd finalProjectBdg

# Run the automated setup script
./setup.sh

# Or manually start the entire stack (API + MySQL)
docker-compose up -d

# Check logs
docker-compose logs -f app

# API will be available at http://localhost:8000
```

**The `setup.sh` script will:**
- Check Docker installation
- Create environment file
- Build and start all services
- Wait for services to be ready
- Provide access URLs and useful commands

That's it! The application will be running with MySQL database.

### Environment Setup Options

#### Option 1: Docker (Any Environment)

**Prerequisites:**
- Docker installed
- Docker Compose installed
- 4GB+ RAM recommended

**Steps:**
```bash
# 1. Clone and enter project
git clone <your-repo-url>
cd finalProjectBdg

# 2. Copy environment file
cp .env.example .env

# 3. Start services
docker-compose up -d

# 4. Check status
docker-compose ps

# 5. View logs
docker-compose logs -f app
```

**Access Points:**
- API: http://localhost:8000
- API Docs: http://localhost:8000/docs
- MySQL: localhost:3306 (user: user, password: password)

#### Option 2: Local Development

**Prerequisites:**
- Python 3.8+
- MySQL server (or use SQLite for testing)
- Git

**Steps:**
```bash
# 1. Clone repository
git clone <your-repo-url>
cd finalProjectBdg

# 2. Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Set up database (choose one):
# Option A: MySQL
# Install MySQL and create database
# Set DATABASE_URL=mysql+pymysql://user:pass@localhost/gaming_stats

# Option B: SQLite (for testing)
# No setup needed - app defaults to SQLite

# 5. Run the application
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

#### Option 3: Cloud Deployment

##### Docker on Cloud VM (AWS EC2, DigitalOcean, etc.)

```bash
# 1. SSH into your VM
ssh user@your-server

# 2. Install Docker and Docker Compose
sudo apt update
sudo apt install docker.io docker-compose
sudo systemctl start docker
sudo usermod -aG docker $USER

# 3. Clone and run
git clone <your-repo-url>
cd finalProjectBdg
docker-compose up -d

# 4. Open firewall port 8000
sudo ufw allow 8000
```

##### Railway, Render, or Heroku

```bash
# 1. Connect your GitHub repo to the platform
# 2. Set environment variables in dashboard:
DATABASE_URL=mysql+pymysql://user:pass@host:port/db
API_HOST=0.0.0.0
API_PORT=8000

# 3. Deploy using Dockerfile.fast for faster builds
```

##### Google Cloud Run

```bash
# 1. Build and push to GCR
gcloud builds submit --tag gcr.io/PROJECT-ID/gaming-stats-api

# 2. Deploy
gcloud run deploy --image gcr.io/PROJECT-ID/gaming-stats-api \
  --platform managed \
  --port 8000 \
  --set-env-vars DATABASE_URL=your_db_url
```

### Environment Variables

Copy `.env.example` to `.env` and customize:

```bash
cp .env.example .env
```

**Required Variables:**
- `DATABASE_URL`: MySQL connection string
- `MYSQL_ROOT_PASSWORD`: MySQL root password
- `MYSQL_DATABASE`: Database name
- `MYSQL_USER`: MySQL user
- `MYSQL_PASSWORD`: MySQL password

**Optional Variables:**
- `API_HOST`: API bind address (default: 0.0.0.0)
- `API_PORT`: API port (default: 8000)

### Database Options

**Production MySQL:**
- Use managed MySQL (AWS RDS, Google Cloud SQL, PlanetScale)
- Set `DATABASE_URL` to your cloud database URL

**Development SQLite:**
- No setup required
- App automatically uses SQLite if no `DATABASE_URL` set
- Data stored in `gaming_stats.db`

### Troubleshooting

**Port already in use:**
```bash
# Change port in docker-compose.yml or .env
# Or stop conflicting service
sudo lsof -i :8000
sudo kill -9 <PID>
```

**Database connection issues:**
```bash
# Check MySQL container
docker-compose logs mysql

# Test connection
docker-compose exec mysql mysql -u user -p gaming_stats
```

**Permission denied (Docker):**
```bash
sudo usermod -aG docker $USER
# Logout and login again
```

**Build cache issues:**
```bash
# Clear Docker cache
docker system prune -a
docker-compose build --no-cache
```

### Development Workflow

```bash
# Start development environment
docker-compose up -d

# Make code changes
# App auto-reloads due to volume mounting

# Run tests
docker-compose exec app pytest

# View database
docker-compose exec mysql mysql -u user -p gaming_stats

# Stop everything
docker-compose down
```

### Production Checklist

- [ ] Set strong database passwords
- [ ] Use environment variables, not hardcoded values
- [ ] Configure proper firewall rules
- [ ] Set up SSL/TLS certificates
- [ ] Configure logging and monitoring
- [ ] Set up backups for database
- [ ] Use production-grade database (not SQLite)

### Using Docker

#### Docker Optimization Features

The Dockerfile is optimized for production use with the following features:

- **Multi-stage build**: Separates build and runtime stages to reduce final image size
- **Minimal base image**: Uses `python:3.11-slim` for a lightweight runtime environment
- **Dependency optimization**: Installs Python packages in a separate build stage with pinned versions
- **Security hardening**: Sets appropriate environment variables to prevent bytecode writing and enable unbuffered output
- **Health checks**: Built-in container health monitoring using netcat
- **Entrypoint script**: Uses a dedicated entrypoint script for proper service startup and database dependency waiting
- **Layer caching**: Optimized layer ordering for better Docker build cache utilization
- **Build cache mounts**: Uses Docker build cache mounts for apt and pip to dramatically reduce build times
- **Fast build variant**: `Dockerfile.fast` provides 80% faster builds (~45 seconds vs ~3.5 minutes) by optimizing dependency installation order

#### Prerequisites
- Docker installed
- Docker Compose installed

#### Quick Start with Docker Compose

The easiest way to run the entire application stack (API + MySQL) is with Docker Compose:

```bash
docker-compose up -d
```

This will:
- Build the Docker image
- Start MySQL database
- Start the FastAPI application
- Expose the API at `http://localhost:8000`

#### View Logs
```bash
docker-compose logs -f app
docker-compose logs -f mysql
```

#### Stop Services
```bash
docker-compose down
```

#### Build Performance

Two Dockerfile variants are available for different use cases:

- **Standard build** (`Dockerfile`): ~2m 21s - Balanced approach with cache mounts
- **Fast build** (`Dockerfile.fast`): ~45s - 80% faster by optimizing layer caching

To use the fast build:
```bash
docker build -f Dockerfile.fast -t gaming-stats-api:fast .
```

Both variants produce identical runtime images with the same functionality.

#### Run Container Manually

```bash
docker run -p 8000:8000 \
  -e DATABASE_URL="mysql+pymysql://user:password@host:3306/gaming_stats" \
  gaming-stats-api:latest
```

#### Environment Variables

Copy `.env.example` to `.env` and customize values as needed:
```bash
cp .env.example .env
```

#### Docker Hub

**Pull from Docker Hub:**
```bash
docker pull abrahamyan001/gaming-stats-api:latest
docker run -p 8000:8000 \
  -e DATABASE_URL="mysql+pymysql://user:password@host:3306/gaming_stats" \
  abrahamyan001/gaming-stats-api:latest
```

**Build and Push to Docker Hub:**
```bash
# Build the image
docker build -t abrahamyan001/gaming-stats-api:latest .

# Login to Docker Hub
docker login --username abrahamyan001

# Push the image
docker push abrahamyan001/gaming-stats-api:latest
```

**View on Docker Hub:**
https://hub.docker.com/r/abrahamyan001/gaming-stats-api

## Dependencies

### Core Dependencies
- **FastAPI** - Modern web framework for building APIs
- **Uvicorn** - ASGI web server
- **SQLAlchemy** - SQL toolkit and ORM
- **Pydantic** - Data validation using Python type annotations
- **PyMySQL** - Pure Python MySQL client
- **cryptography** - Required for MySQL 8.0 authentication with caching_sha2_password

### Development Dependencies
- **pytest** - Testing framework
- **httpx** - HTTP client for testing

### Optional
- **Docker** - For containerization
- **Docker Compose** - For orchestrating multiple containers

See `requirements.txt` for complete list with versions.

## API Endpoints

- `GET /` - Welcome message
- `GET /health` - Health check
- `GET /stats` - Get all gaming statistics
- `GET /stats/{id}` - Get specific stats by ID
- `POST /stats` - Create new gaming stats
- `GET /stats/player/{player_id}` - Get stats by player
- `GET /stats/game/{game_name}` - Get stats by game

## Testing

Run tests with:
```bash
pytest
```

Tests use SQLite database for isolation.
   ```bash
   pip install -e .
   ```

## Running the API

Start the development server:
```bash
source venv/bin/activate
uvicorn app.main:app --reload
```

The API will be available at `http://localhost:8000`

## API Endpoints

- `GET /` - Welcome message
- `GET /stats` - Get all gaming statistics
- `GET /stats/{id}` - Get specific stats by ID
- `POST /stats` - Create new stats entry
- `GET /stats/player/{player_id}` - Get stats for a player
- `GET /stats/game/{game_name}` - Get stats for a game

## Documentation

Interactive API documentation available at `http://localhost:8000/docs`