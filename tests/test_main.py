import pytest
import os
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.main import app, get_db
from app.models import Base

os.environ["DATABASE_URL"] = "sqlite:///:memory:"

TEST_DATABASE_URL = "sqlite:///:memory:"

engine = create_engine(TEST_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db

client = TestClient(app)


@pytest.fixture(autouse=True)
def reset_db():
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)


def test_root():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"message": "Welcome to Gaming Stats API"}


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}


def test_create_stats():
    stats_data = {
        "game_name": "Test Game",
        "player_id": "player123",
        "score": 1000,
        "level": 5,
        "play_time_minutes": 30,
    }
    response = client.post("/stats", json=stats_data)
    assert response.status_code == 201
    data = response.json()
    assert data["game_name"] == "Test Game"
    assert data["player_id"] == "player123"
    assert data["score"] == 1000
    assert "id" in data
    assert "timestamp" in data


def test_get_stats():
    stats_data = {
        "game_name": "Test Game 2",
        "player_id": "player456",
        "score": 2000,
    }
    create_response = client.post("/stats", json=stats_data)
    stats_id = create_response.json()["id"]

    response = client.get(f"/stats/{stats_id}")
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == stats_id
    assert data["game_name"] == "Test Game 2"


def test_get_nonexistent_stats():
    response = client.get("/stats/999")
    assert response.status_code == 404


def test_get_stats_by_player():
    client.post("/stats", json={"game_name": "Chess", "player_id": "samvel", "score": 500})
    client.post("/stats", json={"game_name": "Soccer", "player_id": "samvel", "score": 300})

    response = client.get("/stats/player/samvel")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 2
    assert all(s["player_id"] == "samvel" for s in data)


def test_get_stats_by_game():
    client.post("/stats", json={"game_name": "Chess", "player_id": "p1", "score": 100})
    client.post("/stats", json={"game_name": "Chess", "player_id": "p2", "score": 200})

    response = client.get("/stats/game/Chess")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 2
    assert all(s["game_name"] == "Chess" for s in data)


def test_update_stats():
    create_response = client.post("/stats", json={"game_name": "Chess", "player_id": "p1", "score": 100})
    stats_id = create_response.json()["id"]

    response = client.put(f"/stats/{stats_id}", json={"score": 9999})
    assert response.status_code == 200
    assert response.json()["score"] == 9999


def test_delete_stats():
    create_response = client.post("/stats", json={"game_name": "Chess", "player_id": "p1", "score": 100})
    stats_id = create_response.json()["id"]

    response = client.delete(f"/stats/{stats_id}")
    assert response.status_code == 200

    response = client.get(f"/stats/{stats_id}")
    assert response.status_code == 404