from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from typing import List
from datetime import datetime, timezone
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy import create_engine
from contextlib import asynccontextmanager
import os
import time
import logging
from app.models import GameStats, GameStatsResponse, GameStatsDB, GameStatsUpdate, Base

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

DATABASE_URL = os.getenv("DATABASE_URL", "mysql+pymysql://user:password@localhost/gaming_stats")

engine = create_engine(DATABASE_URL, echo=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


@asynccontextmanager
async def lifespan(app: FastAPI):
    max_retries = 5
    retry_count = 0
    while retry_count < max_retries:
        try:
            logger.info(f"Attempting to connect to database (attempt {retry_count + 1}/{max_retries})")
            Base.metadata.create_all(bind=engine)
            logger.info("Successfully connected to database and created tables")
            break
        except Exception as e:
            retry_count += 1
            logger.error(f"Database connection failed: {str(e)}")
            if retry_count < max_retries:
                logger.info("Retrying in 2 seconds...")
                time.sleep(2)
            else:
                logger.error("Max retries reached. Database may not be available.")
                raise
    yield


app = FastAPI(
    title="Gaming Stats API",
    description="API for managing gaming statistics",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:9000",
        "http://localhost:3000",
        "http://localhost:80",
        "http://localhost",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


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
    return [GameStatsResponse.model_validate(stat) for stat in stats]


# ВАЖНО: маршруты /stats/player/ и /stats/game/ должны быть ДО /stats/{stats_id}
@app.get("/stats/player/{player_id}", response_model=List[GameStatsResponse])
async def get_stats_by_player(player_id: str, db: Session = Depends(get_db)):
    """Get all stats for a specific player"""
    stats = db.query(GameStatsDB).filter(GameStatsDB.player_id == player_id).all()
    return [GameStatsResponse.model_validate(stat) for stat in stats]


@app.get("/stats/game/{game_name}", response_model=List[GameStatsResponse])
async def get_stats_by_game(game_name: str, db: Session = Depends(get_db)):
    """Get all stats for a specific game"""
    stats = db.query(GameStatsDB).filter(GameStatsDB.game_name == game_name).all()
    return [GameStatsResponse.model_validate(stat) for stat in stats]


@app.get("/stats/{stats_id}", response_model=GameStatsResponse)
async def get_stats(stats_id: int, db: Session = Depends(get_db)):
    """Get a specific gaming stats entry by ID"""
    stat = db.query(GameStatsDB).filter(GameStatsDB.id == stats_id).first()
    if not stat:
        raise HTTPException(status_code=404, detail="Stats not found")
    return GameStatsResponse.model_validate(stat)


@app.post("/stats", response_model=GameStatsResponse, status_code=201)
async def create_stats(stats: GameStats, db: Session = Depends(get_db)):
    """Create a new gaming stats entry"""
    stats_dict = stats.model_dump()
    if stats_dict.get("timestamp") is None:
        stats_dict["timestamp"] = datetime.now(timezone.utc)
    db_stat = GameStatsDB(**stats_dict)
    db.add(db_stat)
    db.commit()
    db.refresh(db_stat)
    return GameStatsResponse.model_validate(db_stat)


@app.put("/stats/{stats_id}", response_model=GameStatsResponse)
async def update_stats(stats_id: int, stats: GameStatsUpdate, db: Session = Depends(get_db)):
    """Update a gaming stats entry by ID (partial update allowed)"""
    db_stat = db.query(GameStatsDB).filter(GameStatsDB.id == stats_id).first()
    if not db_stat:
        raise HTTPException(status_code=404, detail="Stats not found")
    update_data = stats.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        if value is not None:
            setattr(db_stat, field, value)
    db.commit()
    db.refresh(db_stat)
    return GameStatsResponse.model_validate(db_stat)


@app.delete("/stats/{stats_id}")
async def delete_stats(stats_id: int, db: Session = Depends(get_db)):
    """Delete a gaming stats entry by ID"""
    stat = db.query(GameStatsDB).filter(GameStatsDB.id == stats_id).first()
    if not stat:
        raise HTTPException(status_code=404, detail="Stats not found")
    db.delete(stat)
    db.commit()
    return {"message": f"Stats entry {stats_id} deleted successfully"}