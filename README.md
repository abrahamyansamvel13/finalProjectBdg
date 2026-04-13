# Gaming Stats API

A REST API for tracking and managing gaming statistics, built with FastAPI, SQLAlchemy, and MySQL. Includes a web dashboard, nginx reverse proxy, and full Docker support.

## Stack

- **Backend** — FastAPI, SQLAlchemy 2.0, Pydantic v2
- **Database** — MySQL 8.0 (SQLite for local dev)
- **Server** — Uvicorn + Nginx reverse proxy
- **Containerization** — Docker, Docker Compose
- **Testing** — pytest, httpx

## Project Structure

```
finalProjectBdg/
├── app/
│   ├── main.py          # API routes and application setup
│   ├── models.py        # SQLAlchemy models and Pydantic schemas
│   └── __init__.py
├── tests/
│   ├── test_main.py     # API tests
│   └── __init__.py
├── index.html           # Frontend dashboard
├── nginx.conf           # Nginx reverse proxy config
├── docker-compose.yml   # Full stack orchestration
├── Dockerfile           # Standard build
├── Dockerfile.fast      # Optimized build (~45s vs ~2m)
├── entrypoint.sh        # Container startup script
├── requirements.txt
└── setup.sh             # Automated setup script
```

## Getting Started

### Option 1 — Docker (recommended)

Runs the full stack: MySQL + FastAPI + Nginx.

```bash
git clone https://github.com/abrahamyansamvel13/finalProjectBdg.git
cd finalProjectBdg
docker-compose up -d --build
```

Access points:

| Service | URL |
|---------|-----|
| API | http://localhost |
| API docs | http://localhost/docs |
| Health check | http://localhost/health |

View logs:
```bash
docker-compose logs -f app
docker-compose logs -f nginx
```

Stop:
```bash
docker-compose down
```

### Option 2 — Local development (SQLite)

No MySQL required — uses SQLite automatically.

```bash
git clone https://github.com/abrahamyansamvel13/finalProjectBdg.git
cd finalProjectBdg

python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Terminal 1 — backend
DATABASE_URL="sqlite:///./dev.db" uvicorn app.main:app --reload

# Terminal 2 — frontend
python3 -m http.server 9000
```

Access points:

| Service | URL |
|---------|-----|
| Dashboard | http://localhost:9000/index.html |
| API | http://localhost:8000 |
| API docs | http://localhost:8000/docs |

## API Reference

### Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| GET | `/stats` | Get all records |
| POST | `/stats` | Create a record |
| GET | `/stats/{id}` | Get record by ID |
| PUT | `/stats/{id}` | Update record (partial) |
| DELETE | `/stats/{id}` | Delete record |
| GET | `/stats/player/{player_id}` | Get records by player |
| GET | `/stats/game/{game_name}` | Get records by game |

### Data model

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

`level`, `play_time_minutes`, and `timestamp` are optional. All fields are optional for PUT requests.

### Examples

```bash
# Create a record
curl -X POST http://localhost:8000/stats \
  -H "Content-Type: application/json" \
  -d '{"game_name": "Chess", "player_id": "player123", "score": 1500, "level": 10}'

# Get all records for a player
curl http://localhost:8000/stats/player/player123

# Update score
curl -X PUT http://localhost:8000/stats/1 \
  -H "Content-Type: application/json" \
  -d '{"score": 2000}'

# Delete a record
curl -X DELETE http://localhost:8000/stats/1
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DATABASE_URL` | SQLite | Full database connection string |
| `MYSQL_ROOT_PASSWORD` | `rootpassword` | MySQL root password |
| `MYSQL_DATABASE` | `gaming_stats` | Database name |
| `MYSQL_USER` | `user` | MySQL user |
| `MYSQL_PASSWORD` | `password` | MySQL password |

For local overrides, copy `.env.example` to `.env`:
```bash
cp .env.example .env
```

## Testing

Tests run against an in-memory SQLite database — no setup needed.

```bash
source venv/bin/activate
pytest tests/ -v
```

## Docker Hub

```bash
# Pull and run
docker pull abrahamyan001/gaming-stats-api:latest
docker run -p 8000:8000 \
  -e DATABASE_URL="mysql+pymysql://user:password@host:3306/gaming_stats" \
  abrahamyan001/gaming-stats-api:latest
```

https://hub.docker.com/r/abrahamyan001/gaming-stats-api

## Troubleshooting

**Port already in use:**
```bash
fuser -k 8000/tcp
fuser -k 9000/tcp
```

**Database connection error:**
```bash
docker-compose logs mysql
docker-compose exec mysql mysql -u user -p gaming_stats
```

**Docker permission denied:**
```bash
sudo usermod -aG docker $USER
# then log out and back in
```

**Build cache issues:**
```bash
docker-compose build --no-cache
```

## Ansible

The project uses Ansible with `ansible_connection=docker` to inspect running containers without SSH or modifying Dockerfiles.

### Requirements

```bash
sudo apt install -y ansible
```

### Files

- `inventory.yml` — defines all three containers as Ansible hosts
- `ansible-ping.sh` — runs infrastructure checks against all containers

### Run checks

```bash
chmod +x ansible-ping.sh
sudo ./ansible-ping.sh
```

Expected output:

```
>>> [1/3] Pinging backend (FastAPI)...
gaming_stats_api | SUCCESS => { "ping": "pong" }

>>> [2/3] Pinging database (MySQL) via raw...
gaming_stats_db | CHANGED | rc=0 >>
mysqld is alive
pong

>>> [3/3] Pinging proxy (Nginx) via raw...
gaming_stats_nginx | CHANGED | rc=0 >>
nginx: configuration file /etc/nginx/nginx.conf test is successful
pong
```

### How it works

Standard containers do not run SSH. Instead of modifying Dockerfiles, Ansible connects to containers natively via `ansible_connection=docker`. Since nginx and MySQL alpine images have no Python, those hosts use the `raw` module which requires only `/bin/sh`.

| Container | Module | Python required |
|-----------|--------|-----------------|
| `gaming_stats_api` | `ping`, `shell` | yes — `/usr/local/bin/python3.11` |
| `gaming_stats_db` | `raw` | no |
| `gaming_stats_nginx` | `raw` | no |