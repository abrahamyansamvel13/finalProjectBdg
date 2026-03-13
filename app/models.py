from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class GameStats(BaseModel):
    game_name: str
    player_id: str
    score: int
    level: Optional[int] = None
    play_time_minutes: Optional[int] = None
    timestamp: Optional[datetime] = None

class GameStatsResponse(GameStats):
    id: int