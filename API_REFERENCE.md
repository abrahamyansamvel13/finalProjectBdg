# 🔌 API Reference & Examples

## Base URL
```
http://localhost:8000
```

## Content-Type
All requests should use: `application/json`

---

## 📋 Complete API Reference

### 1. Health Check
**Endpoint:** `GET /health`

**Request:**
```bash
curl http://localhost:8000/health
```

**Response (200):**
```json
{
  "status": "healthy"
}
```

---

### 2. Get All Stats
**Endpoint:** `GET /stats`

**Request:**
```bash
curl http://localhost:8000/stats
```

**Response (200):**
```json
[
  {
    "game_name": "Chess",
    "player_id": "john_doe_42",
    "score": 9999,
    "level": 20,
    "play_time_minutes": 200,
    "timestamp": "2026-03-26T06:04:09",
    "id": 1
  },
  {
    "game_name": "Soccer League",
    "player_id": "john_doe_42",
    "score": 1250,
    "level": 8,
    "play_time_minutes": 120,
    "timestamp": "2026-04-02T10:30:18",
    "id": 2
  }
]
```

---

### 3. Get Stats by ID
**Endpoint:** `GET /stats/{stats_id}`

**Request:**
```bash
curl http://localhost:8000/stats/1
```

**Response (200):**
```json
{
  "game_name": "Chess",
  "player_id": "john_doe_42",
  "score": 9999,
  "level": 20,
  "play_time_minutes": 200,
  "timestamp": "2026-03-26T06:04:09",
  "id": 1
}
```

**Response (404 - Not Found):**
```json
{
  "detail": "Stats not found"
}
```

---

### 4. Get Stats by Player ID
**Endpoint:** `GET /stats/player/{player_id}`

**Request:**
```bash
curl "http://localhost:8000/stats/player/john_doe_42"
```

**Response (200):**
```json
[
  {
    "game_name": "Chess",
    "player_id": "john_doe_42",
    "score": 9999,
    "level": 20,
    "play_time_minutes": 200,
    "timestamp": "2026-03-26T06:04:09",
    "id": 1
  },
  {
    "game_name": "Soccer League",
    "player_id": "john_doe_42",
    "score": 1250,
    "level": 8,
    "play_time_minutes": 120,
    "timestamp": "2026-04-02T10:30:18",
    "id": 2
  }
]
```

---

### 5. Get Stats by Game Name
**Endpoint:** `GET /stats/game/{game_name}`

**Request:**
```bash
curl "http://localhost:8000/stats/game/Chess"
```

**Response (200):**
```json
[
  {
    "game_name": "Chess",
    "player_id": "john_doe_42",
    "score": 9999,
    "level": 20,
    "play_time_minutes": 200,
    "timestamp": "2026-03-26T06:04:09",
    "id": 1
  }
]
```

---

### 6. Create New Stats Record ⭐
**Endpoint:** `POST /stats`

**Request:**
```bash
curl -X POST http://localhost:8000/stats \
  -H "Content-Type: application/json" \
  -d '{
    "game_name": "Chess Master",
    "player_id": "samvel_pro",
    "score": 2500,
    "level": 15,
    "play_time_minutes": 90
  }'
```

**Request Body Schema:**
```json
{
  "game_name": "string (required)",
  "player_id": "string (required)",
  "score": "integer (required)",
  "level": "integer (optional)",
  "play_time_minutes": "integer (optional)",
  "timestamp": "datetime (optional, auto-generated if omitted)"
}
```

**Response (200 - Created):**
```json
{
  "game_name": "Chess Master",
  "player_id": "samvel_pro",
  "score": 2500,
  "level": 15,
  "play_time_minutes": 90,
  "timestamp": "2026-04-02T14:45:30",
  "id": 5
}
```

**Response (422 - Validation Error):**
```json
{
  "detail": [
    {
      "type": "missing",
      "loc": ["body", "game_name"],
      "msg": "Field required",
      "input": {},
      "url": "https://errors.pydantic.dev/2.5/v/missing"
    }
  ]
}
```

---

### 7. Update Stats Record ⭐
**Endpoint:** `PUT /stats/{stats_id}`

**Request (Full Update):**
```bash
curl -X PUT http://localhost:8000/stats/1 \
  -H "Content-Type: application/json" \
  -d '{
    "game_name": "Chess Pro",
    "player_id": "samvel_pro_v2",
    "score": 5000,
    "level": 25,
    "play_time_minutes": 150
  }'
```

**Request (Partial Update - Only Score):**
```bash
curl -X PUT http://localhost:8000/stats/1 \
  -H "Content-Type: application/json" \
  -d '{
    "score": 10000
  }'
```

**Request (Partial Update - Score & Level):**
```bash
curl -X PUT http://localhost:8000/stats/1 \
  -H "Content-Type: application/json" \
  -d '{
    "score": 7500,
    "level": 20
  }'
```

**Request Body Schema (All Optional):**
```json
{
  "game_name": "string (optional)",
  "player_id": "string (optional)",
  "score": "integer (optional)",
  "level": "integer (optional)",
  "play_time_minutes": "integer (optional)",
  "timestamp": "datetime (optional)"
}
```

**Response (200 - Updated):**
```json
{
  "game_name": "Chess Pro",
  "player_id": "samvel_pro_v2",
  "score": 5000,
  "level": 25,
  "play_time_minutes": 150,
  "timestamp": "2026-03-26T06:04:09",
  "id": 1
}
```

**Response (404 - Not Found):**
```json
{
  "detail": "Stats not found"
}
```

---

### 8. Delete Stats Record ⭐
**Endpoint:** `DELETE /stats/{stats_id}`

**Request:**
```bash
curl -X DELETE http://localhost:8000/stats/1
```

**Response (200 - Deleted):**
```json
{
  "message": "Stats entry 1 deleted successfully"
}
```

**Response (404 - Not Found):**
```json
{
  "detail": "Stats not found"
}
```

---

## 📊 Data Model

### GameStats (Create/Update Request)
```typescript
interface GameStats {
  game_name: string;        // Required - Name of the game
  player_id: string;        // Required - Unique player identifier
  score: number;            // Required - Score achieved
  level?: number;           // Optional - Game level reached
  play_time_minutes?: number; // Optional - Duration in minutes
  timestamp?: DateTime;     // Optional - When played
}
```

### GameStatsResponse (Full Record)
```typescript
interface GameStatsResponse {
  id: number;               // Unique record ID
  game_name: string;
  player_id: string;
  score: number;
  level?: number;
  play_time_minutes?: number;
  timestamp: DateTime;
}
```

### GameStatsUpdate (Partial Update)
```typescript
interface GameStatsUpdate {
  game_name?: string;       // All fields optional for updates
  player_id?: string;
  score?: number;
  level?: number;
  play_time_minutes?: number;
  timestamp?: DateTime;
}
```

---

## 🧪 Common Test Scenarios

### Scenario 1: Add a New Game Record
```bash
curl -X POST http://localhost:8000/stats \
  -H "Content-Type: application/json" \
  -d '{
    "game_name": "Tic Tac Toe",
    "player_id": "alice_123",
    "score": 450,
    "level": 3,
    "play_time_minutes": 15
  }'
```

### Scenario 2: Get All Records for a Player
```bash
curl "http://localhost:8000/stats/player/alice_123"
```

### Scenario 3: Update Record Performance
```bash
curl -X PUT http://localhost:8000/stats/2 \
  -H "Content-Type: application/json" \
  -d '{
    "score": 600,
    "level": 4,
    "play_time_minutes": 20
  }'
```

### Scenario 4: Get Game Leaderboard
```bash
curl "http://localhost:8000/stats/game/Tic Tac Toe"
```

### Scenario 5: Delete Old Record
```bash
curl -X DELETE http://localhost:8000/stats/2
```

### Scenario 6: Verify All Records
```bash
curl http://localhost:8000/stats
```

---

## 🔍 Query Parameters

Currently, these endpoints don't use query parameters. All filtering is done via URL paths:
- `/stats` - All records
- `/stats/{id}` - Specific ID
- `/stats/player/{player_id}` - Specific player
- `/stats/game/{game_name}` - Specific game

---

## ⚙️ HTTP Status Codes

| Code | Meaning | Example |
|------|---------|---------|
| 200 | Success | Record created/updated/retrieved |
| 404 | Not Found | Record ID doesn't exist |
| 422 | Validation Error | Missing required fields |
| 500 | Server Error | Database connection failed |

---

## 🔐 Authentication

Currently, **no authentication is required** (development mode).

For production, add:
- JWT tokens
- API keys
- OAuth2
- User roles

---

## 📡 Pagination (Future Enhancement)

Currently returns all records. For pagination, could add:
```bash
GET /stats?skip=0&limit=10
GET /stats/player/{player_id}?skip=0&limit=5
```

---

## 🔄 Error Handling

### Validation Error Example
```json
{
  "detail": [
    {
      "type": "missing",
      "loc": ["body", "game_name"],
      "msg": "Field required"
    }
  ]
}
```

### Not Found Error Example
```json
{
  "detail": "Stats not found"
}
```

---

## 💡 Pro Tips

1. **Use `-s` flag for clean cURL output:**
   ```bash
   curl -s http://localhost:8000/stats
   ```

2. **Format JSON response:**
   ```bash
   curl -s http://localhost:8000/stats | python3 -m json.tool
   ```

3. **Count records:**
   ```bash
   curl -s http://localhost:8000/stats | python3 -m json.tool | grep '"id"' | wc -l
   ```

4. **Save response to file:**
   ```bash
   curl -s http://localhost:8000/stats > stats.json
   ```

5. **Use interactive API docs:**
   ```
   http://localhost:8000/docs
   ```
   (Try requests directly in browser)

---

## 🚀 Example Workflow

```bash
# 1. Add new record
curl -X POST http://localhost:8000/stats \
  -H "Content-Type: application/json" \
  -d '{"game_name": "Game1", "player_id": "user1", "score": 100, "level": 1, "play_time_minutes": 30}'

# 2. View it
curl http://localhost:8000/stats

# 3. Update it
curl -X PUT http://localhost:8000/stats/1 \
  -H "Content-Type: application/json" \
  -d '{"score": 200}'

# 4. View again
curl http://localhost:8000/stats

# 5. Delete it
curl -X DELETE http://localhost:8000/stats/1

# 6. Confirm deletion
curl http://localhost:8000/stats
```

---

Happy API testing! 🎉
