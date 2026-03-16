from fastapi import FastAPI, HTTPException, Depends
from typing import List
from datetime import datetime, timezone
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy import create_engine
from contextlib import asynccontextmanager
import os
from app.models import GameStats, GameStatsResponse, GameStatsDB, Base

# Database setup
DATABASE_URL = os.getenv("DATABASE_URL", "mysql+pymysql://user:password@localhost/gaming_stats")

engine = create_engine(DATABASE_URL, echo=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Create tables on startup
    Base.metadata.create_all(bind=engine)
    yield
    # Cleanup if needed

app = FastAPI(title="Gaming Stats API", description="API for managing gaming statistics", version="0.1.0", lifespan=lifespan)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.get("/")
async def root():
    return {"message": "Welcome to Gaming Stats API"}

@app.get("/health")
async def health():
    return {"status": "healthy"}

@app.get("/stats", response_model=List[GameStatsResponse])
async def get_all_stats(db: Session = Depends(get_db)):
    """Get all gaming statistics"""
    stats = db.query(GameStatsDB).all()
    return [GameStatsResponse(**stat.__dict__) for stat in stats]

@app.get("/stats/{stats_id}", response_model=GameStatsResponse)
async def get_stats(stats_id: int, db: Session = Depends(get_db)):
    """Get a specific gaming stats entry by ID"""
    stat = db.query(GameStatsDB).filter(GameStatsDB.id == stats_id).first()
    if not stat:
        raise HTTPException(status_code=404, detail="Stats not found")
    return GameStatsResponse(**stat.__dict__)

@app.post("/stats", response_model=GameStatsResponse)
async def create_stats(stats: GameStats, db: Session = Depends(get_db)):
    """Create a new gaming stats entry"""
    stats_dict = stats.model_dump()
    if stats_dict.get("timestamp") is None:
        stats_dict["timestamp"] = datetime.now(timezone.utc)
    
    db_stat = GameStatsDB(**stats_dict)
    db.add(db_stat)
    db.commit()
    db.refresh(db_stat)
    return GameStatsResponse(**db_stat.__dict__)

@app.get("/stats/player/{player_id}", response_model=List[GameStatsResponse])
async def get_stats_by_player(player_id: str, db: Session = Depends(get_db)):
    """Get all stats for a specific player"""
    stats = db.query(GameStatsDB).filter(GameStatsDB.player_id == player_id).all()
    return [GameStatsResponse(**stat.__dict__) for stat in stats]

@app.get("/stats/game/{game_name}", response_model=List[GameStatsResponse])
async def get_stats_by_game(game_name: str, db: Session = Depends(get_db)):
    """Get all stats for a specific game"""
    stats = db.query(GameStatsDB).filter(GameStatsDB.game_name == game_name).all()
    return [GameStatsResponse(**stat.__dict__) for stat in stats]