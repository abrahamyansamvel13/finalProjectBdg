# Gaming Stats API

A FastAPI-based REST API for managing gaming statistics.

## Features

- Create and retrieve gaming statistics
- Filter stats by player or game
- RESTful API endpoints
- Built with FastAPI and Pydantic

## Installation

1. Clone the repository
2. Create and activate a virtual environment:
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   ```
3. Install dependencies:
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