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
- 🔄 **Multi-stage Docker build** - Optimized image size
- 🏥 **Health checks** - Built-in container health monitoring
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

## Running the Application

### Local Development

```bash
uvicorn app.main:app --reload
```

The API will be available at `http://localhost:8000`

### Using Docker

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

#### Build Docker Image Manually

```bash
docker build -t gaming-stats-api:latest .
```

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