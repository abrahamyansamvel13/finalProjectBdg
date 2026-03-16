from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column

class Base(DeclarativeBase):
    pass

class GameStatsDB(Base):
    __tablename__ = "game_stats"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    game_name: Mapped[str] = mapped_column(String(255), nullable=False)
    player_id: Mapped[str] = mapped_column(String(255), nullable=False)
    score: Mapped[int] = mapped_column(Integer, nullable=False)
    level: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    play_time_minutes: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    timestamp: Mapped[datetime] = mapped_column(DateTime, nullable=False, default=datetime.utcnow)

class GameStats(BaseModel):
    game_name: str
    player_id: str
    score: int
    level: Optional[int] = None
    play_time_minutes: Optional[int] = None
    timestamp: Optional[datetime] = None

class GameStatsResponse(GameStats):
    id: int