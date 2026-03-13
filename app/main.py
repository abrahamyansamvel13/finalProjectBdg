from fastapi import FastAPI, HTTPException
from typing import List
from datetime import datetime, timezone
from app.models import GameStats, GameStatsResponse

app = FastAPI(title="Gaming Stats API", description="API for managing gaming statistics", version="0.1.0")

# In-memory storage for demo purposes
stats_db = []
stats_id_counter = 1

@app.get("/")
async def root():
    return {"message": "Welcome to Gaming Stats API"}

@app.get("/stats", response_model=List[GameStatsResponse])
async def get_all_stats():
    """Get all gaming statistics"""
    return stats_db

@app.get("/stats/{stats_id}", response_model=GameStatsResponse)
async def get_stats(stats_id: int):
    """Get a specific gaming stats entry by ID"""
    for stat in stats_db:
        if stat["id"] == stats_id:
            return stat
    raise HTTPException(status_code=404, detail="Stats not found")

@app.post("/stats", response_model=GameStatsResponse)
async def create_stats(stats: GameStats):
    """Create a new gaming stats entry"""
    global stats_id_counter
    stats_dict = stats.model_dump()
    stats_dict["id"] = stats_id_counter
    if stats_dict.get("timestamp") is None:
        stats_dict["timestamp"] = datetime.now(timezone.utc)
    stats_db.append(stats_dict)
    stats_id_counter += 1
    return stats_dict

@app.get("/stats/player/{player_id}", response_model=List[GameStatsResponse])
async def get_stats_by_player(player_id: str):
    """Get all stats for a specific player"""
    return [stat for stat in stats_db if stat["player_id"] == player_id]

@app.get("/stats/game/{game_name}", response_model=List[GameStatsResponse])
async def get_stats_by_game(game_name: str):
    """Get all stats for a specific game"""
    return [stat for stat in stats_db if stat["game_name"] == game_name]