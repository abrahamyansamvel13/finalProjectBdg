# 🚀 Quick Start Guide

## ⚡ Start the Project (5 minutes)

### Terminal 1: Backend
```bash
cd /home/samvel/Документы/finalProjectBdg
source venv/bin/activate
uvicorn app.main:app --reload
```

### Terminal 2: Frontend
```bash
cd /home/samvel/Документы/finalProjectBdg
python3 -m http.server 9000
```

### Open in Browser
```
http://localhost:9000/index.html
```

---

## 🎯 All Available Commands

### View Database
```bash
python view_db.py
```

### Test API
```bash
# Get all records
curl http://localhost:8000/stats

# Add record
curl -X POST http://localhost:8000/stats \
  -H "Content-Type: application/json" \
  -d '{"game_name": "Game", "player_id": "player1", "score": 100, "level": 5, "play_time_minutes": 30}'

# Update record (partial)
curl -X PUT http://localhost:8000/stats/1 \
  -H "Content-Type: application/json" \
  -d '{"score": 500}'

# Delete record
curl -X DELETE http://localhost:8000/stats/1

# Get by player
curl http://localhost:8000/stats/player/player1

# Get by game
curl http://localhost:8000/stats/game/Chess
```

---

## 📋 All Changes Made

### 1. Backend (`app/main.py`)
- ✅ Added CORS support
- ✅ Added DELETE endpoint
- ✅ Added PUT endpoint with partial updates

### 2. Models (`app/models.py`)
- ✅ Added GameStatsUpdate model for flexible updates

### 3. Database Script (`view_db.py`)
- ✅ Auto-creates tables if missing
- ✅ Better error handling

### 4. Frontend (`index.html`) - NEW
- ✅ Beautiful dashboard
- ✅ Add/Update/Delete records
- ✅ View all records table
- ✅ Real-time updates
- ✅ Responsive design

---

## 🛠️ Available Endpoints

### GET (Read)
- `GET /` - Welcome message
- `GET /health` - Health check
- `GET /stats` - All records
- `GET /stats/{id}` - Record by ID
- `GET /stats/player/{player_id}` - By player
- `GET /stats/game/{game_name}` - By game
- `GET /docs` - Interactive API docs

### POST (Create)
- `POST /stats` - Create new record

### PUT (Update)
- `PUT /stats/{id}` - Update record (partial)

### DELETE (Delete)
- `DELETE /stats/{id}` - Delete record

---

## 📊 Sample Data

Currently in database:
- Record 1: Chess - Score 9999, Level 20
- Record 2: Soccer League - Score 1250, Level 8
- Record 3: Soccer League - Score 5000, Level 15
- Record 4: Soccer League - Score 1250, Level 8

---

## 🔗 URLs

| Service | URL |
|---------|-----|
| Frontend | http://localhost:9000/index.html |
| API | http://localhost:8000 |
| API Docs | http://localhost:8000/docs |
| Health Check | http://localhost:8000/health |

---

## ❌ Troubleshooting

### Port in use?
```bash
lsof -i :8000 | awk 'NR!=1 {print $2}' | xargs kill -9
lsof -i :9000 | awk 'NR!=1 {print $2}' | xargs kill -9
```

### Module not found?
```bash
source venv/bin/activate
pip install -r requirements.txt
```

### Database error?
```bash
python view_db.py
```

---

## 📁 Important Files

- `index.html` - Frontend dashboard
- `app/main.py` - Backend API
- `app/models.py` - Database models
- `view_db.py` - Database viewer
- `PROJECT_GUIDE.md` - Full documentation
- `test.db` - SQLite database (auto-created)

---

## 🎮 Use Cases

**Add a score:**
1. Fill form on left
2. Click "Add Record"
3. See it in table

**Update a score:**
1. Enter ID and new values
2. Click "Update Record"

**Delete a score:**
1. Click trash icon
2. Confirm deletion

**View all:**
- Everything shows in right panel table
- Refreshes automatically

---

Happy gaming! 🎮
