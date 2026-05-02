# 🎮 Gaming Stats Dashboard - Complete Project Guide

## 📋 Table of Contents
1. [Project Overview](#project-overview)
2. [Changes Made](#changes-made)
3. [Project Structure](#project-structure)
4. [Installation & Setup](#installation--setup)
5. [How to Run](#how-to-run)
6. [API Documentation](#api-documentation)
7. [Frontend Features](#frontend-features)
8. [Use Cases & Examples](#use-cases--examples)
9. [Troubleshooting](#troubleshooting)

---

## 📱 Project Overview

**Gaming Stats Dashboard** is a full-stack web application for managing gaming statistics. It includes:
- ✅ FastAPI backend with SQLAlchemy ORM
- ✅ SQLite database for data persistence
- ✅ Interactive HTML/CSS/JavaScript frontend
- ✅ Complete CRUD operations (Create, Read, Update, Delete)
- ✅ Real-time data synchronization
- ✅ Responsive design for all devices

---

## 🔄 Changes Made

### 1. **Backend Changes** (`app/main.py`)

#### Added Features:
- ✅ **CORS Middleware** - Enables frontend to communicate with backend
  ```python
  app.add_middleware(
      CORSMiddleware,
      allow_origins=["*"],
      allow_credentials=True,
      allow_methods=["*"],
      allow_headers=["*"],
  )
  ```

- ✅ **DELETE Endpoint** - Delete game records by ID
  ```
  DELETE /stats/{stats_id}
  ```

- ✅ **PUT Endpoint** - Update game records (partial updates supported)
  ```
  PUT /stats/{stats_id}
  ```

### 2. **Model Changes** (`app/models.py`)

#### New Model Created:
- ✅ **GameStatsUpdate** - For partial record updates
  - All fields optional (can update just score, or level, or any combination)
  - Prevents "Field required" errors
  
```python
class GameStatsUpdate(BaseModel):
    game_name: Optional[str] = None
    player_id: Optional[str] = None
    score: Optional[int] = None
    level: Optional[int] = None
    play_time_minutes: Optional[int] = None
    timestamp: Optional[datetime] = None
```

### 3. **Database Script Enhancement** (`view_db.py`)

#### Improvements:
- ✅ **Auto Table Creation** - Creates `game_stats` table if it doesn't exist
- ✅ **Better Error Handling** - More informative error messages
- ✅ **Imports Models** - Uses SQLAlchemy models for consistency

### 4. **Frontend Creation** (`index.html`)

#### Built a Complete Dashboard with:
- ✅ **Add Records Form** - Create new game stats entries
- ✅ **Update Records Form** - Modify existing records partially
- ✅ **View All Records** - Display in formatted table
- ✅ **Delete Records** - Remove entries with confirmation
- ✅ **Real-time Updates** - Auto-refresh after each action
- ✅ **Success/Error Messages** - User feedback for all operations
- ✅ **Responsive Design** - Works on desktop and mobile

---

## 📁 Project Structure

```
finalProjectBdg/
├── app/
│   ├── __init__.py
│   ├── main.py              ← Backend API (FastAPI)
│   ├── models.py            ← Database models
│   └── __pycache__/
├── tests/
│   ├── __init__.py
│   └── test_main.py
├── index.html               ← ✨ NEW: Frontend Dashboard
├── view_db.py               ← Enhanced: Auto-creates tables
├── requirements.txt         ← Dependencies
├── setup.sh                 ← Setup script
├── venv/                    ← Virtual environment
├── test.db                  ← SQLite database (auto-created)
├── docker-compose.yml
├── Dockerfile
├── nginx.conf
└── README.md
```

---

## 🚀 Installation & Setup

### Prerequisites
- Python 3.8+
- pip or conda
- Modern web browser (Firefox, Chrome, Safari, Edge)

### Step 1: Clone/Navigate to Project
```bash
cd /home/samvel/Документы/finalProjectBdg
```

### Step 2: Create Virtual Environment (if not exists)
```bash
python3 -m venv venv
source venv/bin/activate
```

### Step 3: Install Dependencies
```bash
pip install -r requirements.txt
```

**Requirements includes:**
- fastapi==0.104.1
- uvicorn==0.24.0
- pydantic==2.5.0
- pytest==7.4.3
- httpx==0.25.2
- PyMySQL==1.1.0
- SQLAlchemy==2.0.23
- cryptography==41.0.7

---

## 🎯 How to Run

### Quick Start (Single Command)
```bash
# Terminal 1: Start Backend
source venv/bin/activate && uvicorn app.main:app --reload

# Terminal 2: Start Frontend (in new terminal)
cd /home/samvel/Документы/finalProjectBdg
python3 -m http.server 9000
```

### Detailed Steps

#### Option 1: Development Mode (Recommended)

**Terminal 1 - Start Backend API:**
```bash
cd /home/samvel/Документы/finalProjectBdg
source venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Expected output:
```
INFO:     Uvicorn running on http://0.0.0.0:8000
INFO:     Application startup complete
```

**Terminal 2 - Start Frontend Server:**
```bash
cd /home/samvel/Документы/finalProjectBdg
python3 -m http.server 9000
```

Expected output:
```
Serving HTTP on 0.0.0.0 port 9000
```

**Terminal 3 - Access Dashboard:**
- Open browser: `http://localhost:9000/index.html`
- Or: `http://127.0.0.1:9000/index.html`

---

#### Option 2: Using Docker
```bash
cd /home/samvel/Документы/finalProjectBdg
docker-compose up
```

---

#### Option 3: View Database (Without Frontend)
```bash
source venv/bin/activate
python view_db.py
```

---

## 📡 API Documentation

### Base URL
```
http://localhost:8000
```

### Interactive API Docs (Swagger UI)
```
http://localhost:8000/docs
```

### Available Endpoints

#### 1. **Health Check**
```
GET /health
```
**Response:**
```json
{"status": "healthy"}
```

---

#### 2. **Get All Records**
```
GET /stats
```
**Response:**
```json
[
  {
    "id": 1,
    "game_name": "Chess",
    "player_id": "john_doe_42",
    "score": 9999,
    "level": 20,
    "play_time_minutes": 200,
    "timestamp": "2026-03-26T06:04:09"
  }
]
```

---

#### 3. **Get Record by ID**
```
GET /stats/{id}
```
**Example:** `GET /stats/1`

**Response:**
```json
{
  "id": 1,
  "game_name": "Chess",
  "player_id": "john_doe_42",
  "score": 9999,
  "level": 20,
  "play_time_minutes": 200,
  "timestamp": "2026-03-26T06:04:09"
}
```

---

#### 4. **Get Records by Player**
```
GET /stats/player/{player_id}
```
**Example:** `GET /stats/player/john_doe_42`

**Response:**
```json
[
  {
    "id": 1,
    "game_name": "Chess",
    ...
  },
  {
    "id": 2,
    "game_name": "Soccer League",
    ...
  }
]
```

---

#### 5. **Get Records by Game**
```
GET /stats/game/{game_name}
```
**Example:** `GET /stats/game/Chess`

**Response:** Array of records for that game

---

#### 6. **Create New Record** ✨
```
POST /stats
Content-Type: application/json
```

**Request Body:**
```json
{
  "game_name": "Soccer League",
  "player_id": "john_doe_42",
  "score": 1250,
  "level": 8,
  "play_time_minutes": 120
}
```

**Response:**
```json
{
  "id": 5,
  "game_name": "Soccer League",
  "player_id": "john_doe_42",
  "score": 1250,
  "level": 8,
  "play_time_minutes": 120,
  "timestamp": "2026-04-02T14:30:00"
}
```

**Using cURL:**
```bash
curl -X POST http://localhost:8000/stats \
  -H "Content-Type: application/json" \
  -d '{
    "game_name": "Soccer League",
    "player_id": "john_doe_42",
    "score": 1250,
    "level": 8,
    "play_time_minutes": 120
  }'
```

---

#### 7. **Update Record** ✨ (NEW)
```
PUT /stats/{id}
Content-Type: application/json
```

**Request Body (Partial Update):**
```json
{
  "score": 5000,
  "level": 15
}
```

**Response:**
```json
{
  "id": 1,
  "game_name": "Chess",
  "player_id": "john_doe_42",
  "score": 5000,
  "level": 15,
  "play_time_minutes": 200,
  "timestamp": "2026-03-26T06:04:09"
}
```

**Using cURL:**
```bash
# Update just score
curl -X PUT http://localhost:8000/stats/1 \
  -H "Content-Type: application/json" \
  -d '{"score": 5000}'

# Update multiple fields
curl -X PUT http://localhost:8000/stats/1 \
  -H "Content-Type: application/json" \
  -d '{"score": 5000, "level": 15, "play_time_minutes": 200}'
```

---

#### 8. **Delete Record** ✨ (NEW)
```
DELETE /stats/{id}
```

**Response:**
```json
{"message": "Stats entry 1 deleted successfully"}
```

**Using cURL:**
```bash
curl -X DELETE http://localhost:8000/stats/1
```

---

## 🎨 Frontend Features

### Dashboard Sections

#### Left Panel: **Add New Record**
- 📝 Game Name (required)
- 👤 Player ID (required)
- 🎯 Score (required)
- 📊 Level (optional)
- ⏱️ Play Time in minutes (optional)
- ✅ Success message after creation

#### Left Panel: **Update Record**
- 🔍 Record ID (required)
- Optional fields (update any combination)
- Partial updates supported
- ✅ Success message after update

#### Right Panel: **View All Records**
- 📋 Table with all entries
- 🗑️ Delete buttons on each row
- 📊 Record count display
- ⏰ Timestamp on hover
- Auto-refresh after each operation

### UI Features
- 🎨 Modern purple gradient design
- 📱 Responsive (works on mobile/tablet/desktop)
- ⚡ Real-time updates
- 💬 Toast notifications (success/error messages)
- 🔄 Auto-refresh after operations
- ✨ Smooth animations and transitions

---

## 📚 Use Cases & Examples

### Use Case 1: Track Gaming Progress

**Scenario:** You want to track your chess game scores

**Steps:**
1. Open `http://localhost:9000/index.html`
2. Fill "Add New Record" form:
   - Game Name: `Chess Master`
   - Player ID: `samvel_pro`
   - Score: `1500`
   - Level: `10`
   - Play Time: `60`
3. Click "➕ Add Record"
4. See it appear in the table instantly

---

### Use Case 2: Update Your Score After Playing

**Scenario:** You finished a game with a better score

**Steps:**
1. In "Update Record" section:
   - Record ID: `1`
   - Score: `5000`
   - Level: `25`
2. Click "⬆️ Update Record"
3. Record updates immediately in the table

---

### Use Case 3: Compare Player Performance

**Scenario:** Check stats for a specific player using API

**Command:**
```bash
curl http://localhost:8000/stats/player/john_doe_42 | python3 -m json.tool
```

**Result:** Shows all games played by john_doe_42

---

### Use Case 4: Get Leaderboard by Game

**Scenario:** Find all records for a specific game

**Command:**
```bash
curl http://localhost:8000/stats/game/Chess | python3 -m json.tool
```

---

### Use Case 5: Delete Old Records

**Steps:**
1. Find record in table
2. Click 🗑️ button
3. Confirm deletion
4. Record removed from database

---

## 🔧 Troubleshooting

### Problem 1: Port Already in Use

**Error:**
```
ERROR: [Errno 98] Address already in use
```

**Solution:**
```bash
# Kill process on port 8000
lsof -i :8000 | grep -v COMMAND | awk '{print $2}' | xargs kill -9

# Or use different port
uvicorn app.main:app --port 8001
```

### Problem 2: ModuleNotFoundError

**Error:**
```
ModuleNotFoundError: No module named 'fastapi'
```

**Solution:**
```bash
# Ensure virtual environment is activated
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### Problem 3: Database Table Not Found

**Error:**
```
sqlite3.OperationalError: no such table: game_stats
```

**Solution:**
```bash
# Run the view script to auto-create tables
python view_db.py

# Or restart FastAPI server
```

### Problem 4: CORS Error in Browser

**Error:**
```
Access to XMLHttpRequest at 'http://localhost:8000/stats' from origin 
'http://localhost:9000' has been blocked by CORS policy
```

**Solution:**
- ✅ Already fixed! CORS middleware is enabled in `app/main.py`
- Make sure FastAPI server is running

### Problem 5: Frontend Shows "Cannot Connect"

**Solution:**
1. Check FastAPI is running on port 8000:
   ```bash
   curl http://localhost:8000/health
   ```

2. Check HTTP server on port 9000:
   ```bash
   curl http://localhost:9000/index.html
   ```

3. Verify both are built in different terminals

---

## 📊 Database Schema

### game_stats Table

```sql
CREATE TABLE game_stats (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    game_name VARCHAR(255) NOT NULL,
    player_id VARCHAR(255) NOT NULL,
    score INTEGER NOT NULL,
    level INTEGER NULL,
    play_time_minutes INTEGER NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### Record Example

| id | game_name | player_id | score | level | play_time_minutes | timestamp |
|----|-----------|-----------|-------|-------|-------------------|-----------|
| 1 | Chess | john_doe_42 | 9999 | 20 | 200 | 2026-03-26 06:04:09 |
| 2 | Soccer League | john_doe_42 | 1250 | 8 | 120 | 2026-04-02 10:30:18 |

---

## 🎯 Quick Reference

### Start Everything
```bash
# Terminal 1
source venv/bin/activate && uvicorn app.main:app --reload

# Terminal 2 (new)
python3 -m http.server 9000

# Open in browser
# http://localhost:9000/index.html
```

### View Database
```bash
source venv/bin/activate
python view_db.py
```

### Test API with cURL
```bash
# Get all records
curl http://localhost:8000/stats

# Add new record
curl -X POST http://localhost:8000/stats \
  -H "Content-Type: application/json" \
  -d '{"game_name": "Game", "player_id": "player1", "score": 100}'

# Update record
curl -X PUT http://localhost:8000/stats/1 \
  -H "Content-Type: application/json" \
  -d '{"score": 500}'

# Delete record
curl -X DELETE http://localhost:8000/stats/1
```

---

## 📝 Summary of Changes

| File | Changes |
|------|---------|
| `app/main.py` | ✅ Added CORS middleware, DELETE endpoint, PUT endpoint |
| `app/models.py` | ✅ Added GameStatsUpdate model |
| `view_db.py` | ✅ Enhanced with auto table creation |
| `index.html` | ✅ **NEW**: Complete frontend dashboard |

---

## 🎉 You're All Set!

Your Gaming Stats Dashboard is now fully functional with:
- ✅ Complete CRUD API
- ✅ Professional frontend
- ✅ Database persistence
- ✅ Real-time updates
- ✅ Error handling
- ✅ Production-ready code

**Next Steps:**
1. Open the dashboard: `http://localhost:9000/index.html`
2. Add some game records
3. Experiment with updates and deletions
4. Check the database: `python view_db.py`

Enjoy! 🎮
