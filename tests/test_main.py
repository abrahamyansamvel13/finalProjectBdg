import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_root():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"message": "Welcome to Gaming Stats API"}

def test_create_stats():
    stats_data = {
        "game_name": "Test Game",
        "player_id": "player123",
        "score": 1000,
        "level": 5,
        "play_time_minutes": 30
    }
    response = client.post("/stats", json=stats_data)
    assert response.status_code == 200
    data = response.json()
    assert data["game_name"] == "Test Game"
    assert data["player_id"] == "player123"
    assert data["score"] == 1000
    assert "id" in data
    assert "timestamp" in data

def test_get_stats():
    # First create a stats entry
    stats_data = {
        "game_name": "Test Game 2",
        "player_id": "player456",
        "score": 2000
    }
    create_response = client.post("/stats", json=stats_data)
    stats_id = create_response.json()["id"]

    # Then retrieve it
    response = client.get(f"/stats/{stats_id}")
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == stats_id
    assert data["game_name"] == "Test Game 2"

def test_get_nonexistent_stats():
    response = client.get("/stats/999")
    assert response.status_code == 404