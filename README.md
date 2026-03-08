# MyLearnTracker 📚

A simple personal learning goal tracker built with Python + Flask.
Track courses you want to learn, update your progress, and stay on target.

---

## What Does It Do?

MyLearnTracker is a REST API that lets you:

- ➕ Add courses with a name, description, target date, and status
- 📋 View all your courses (or just one by ID)
- ✏️ Update any field — including marking a course as completed
- 🗑️ Delete courses you no longer need
- 📊 Get a statistics summary (how many Not Started / In Progress / Completed)
- 🔍 Search courses by name or description keyword

All data is stored in a plain `courses.json` file — no database required.

---

## Project Structure

```
mylearn-tracker/
├── app.py              # The entire Flask application (one file!)
├── courses.json        # Auto-created when you first run the app
├── requirements.txt    # Python dependencies (just Flask)
├── test_api.sh         # Bash script to test every endpoint
└── README.md           # This file
```

---

## Prerequisites

- Python 3.7 or higher
- pip (comes with Python)
- A terminal / command prompt
- curl (for testing — installed by default on Mac/Linux)

---

## Installation

**1. Clone or download the project files into a folder:**

```bash
mkdir mylearn-tracker
cd mylearn-tracker
# Place app.py, requirements.txt, test_api.sh here
```

**2. Install dependencies:**

```bash
pip install -r requirements.txt
```

---

## Running the Application

```bash
python app.py
```

You should see:

```
============================================================
  MyLearnTracker API is starting...
============================================================
  Data file: /path/to/courses.json
  API URL:   http://localhost:5000
============================================================
  Press CTRL+C to stop
```

The API is now live at **http://localhost:5000**

> Keep this terminal open while testing. Open a second terminal for your curl commands.

---

## API Endpoints

### `GET /`
Returns a welcome message and lists all available endpoints.

```bash
curl http://localhost:5000
```

---

### `GET /api/courses`
Returns all courses.

```bash
curl http://localhost:5000/api/courses
```

**Response:**
```json
{
  "success": true,
  "count": 2,
  "courses": [
    {
      "id": 1,
      "name": "Python Basics",
      "description": "Learn Python fundamentals",
      "target_date": "2025-12-31",
      "status": "In Progress",
      "created_at": "2025-11-04 10:30:00"
    }
  ]
}
```

---

### `GET /api/courses/<id>`
Returns one course by its integer ID.

```bash
curl http://localhost:5000/api/courses/1
```

---

### `POST /api/courses`
Adds a new course. All four fields are required.

| Field | Type | Valid values |
|-------|------|-------------|
| `name` | string | Any text |
| `description` | string | Any text |
| `target_date` | string | Format: `YYYY-MM-DD` |
| `status` | string | `Not Started`, `In Progress`, `Completed` |

```bash
curl -X POST http://localhost:5000/api/courses \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Python Basics",
    "description": "Learn Python fundamentals including variables, loops, and functions",
    "target_date": "2025-12-31",
    "status": "Not Started"
  }'
```

**Response (201 Created):**
```json
{
  "success": true,
  "message": "Course added successfully",
  "course": {
    "id": 1,
    "name": "Python Basics",
    "description": "Learn Python fundamentals...",
    "target_date": "2025-12-31",
    "status": "Not Started",
    "created_at": "2025-11-04 10:30:00"
  }
}
```

---

### `PUT /api/courses/<id>`
Updates one or more fields on an existing course. Only include the fields you want to change.

```bash
# Update just the status
curl -X PUT http://localhost:5000/api/courses/1 \
  -H "Content-Type: application/json" \
  -d '{"status": "In Progress"}'

# Update multiple fields at once
curl -X PUT http://localhost:5000/api/courses/1 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Advanced Python",
    "target_date": "2026-01-15",
    "status": "Completed"
  }'
```

---

### `DELETE /api/courses/<id>`
Permanently removes a course.

```bash
curl -X DELETE http://localhost:5000/api/courses/1
```

---

### `GET /api/courses/stats` ⭐ Bonus
Returns a count of courses broken down by status.

```bash
curl http://localhost:5000/api/courses/stats
```

**Response:**
```json
{
  "success": true,
  "statistics": {
    "total_courses": 5,
    "not_started": 2,
    "in_progress": 2,
    "completed": 1
  }
}
```

---

### `GET /api/courses/search?q=<term>` ⭐ Bonus
Searches course names and descriptions (case-insensitive).

```bash
curl "http://localhost:5000/api/courses/search?q=python"
```

---

## Error Handling

The API returns clear error messages for every failure case:

| Scenario | HTTP Status | Example response |
|----------|-------------|-----------------|
| Missing required field | 400 | `{"success": false, "error": "Missing required fields: description, status"}` |
| Invalid status value | 400 | `{"success": false, "error": "Invalid status. Must be one of: Not Started, In Progress, Completed"}` |
| Course not found | 404 | `{"success": false, "error": "Course with ID 99 not found"}` |
| No JSON body sent | 400 | `{"success": false, "error": "No JSON data provided"}` |
| Unknown endpoint | 404 | `{"success": false, "error": "Endpoint not found"}` |

---

## Testing

### Option A: Bash test script (automated)

```bash
chmod +x test_api.sh
./test_api.sh
```

Runs all 12 tests and prints PASS / FAIL for each.

### Option B: Manual curl testing

Follow the example commands in the **API Endpoints** section above.

### Option C: Postman

Import `MyLearnTracker_Postman_Collection.json` into Postman and run the requests in order.

---

## How Data is Stored

All courses are saved in `courses.json` as a JSON array:

```json
[
  {
    "id": 1,
    "name": "Python Basics",
    "description": "Learn Python fundamentals",
    "target_date": "2025-12-31",
    "status": "Not Started",
    "created_at": "2025-11-04 10:30:00"
  }
]
```

This file is created automatically on first run. You can open it in any text editor to inspect your data directly.

---

## Troubleshooting

**"No module named flask"**
```bash
pip install -r requirements.txt
```

**"Address already in use" / Port 5000 busy**

Something else is running on port 5000. Change the port at the bottom of `app.py`:
```python
app.run(debug=True, host='0.0.0.0', port=5001)  # Changed to 5001
```
Then test against `http://localhost:5001`

**"Permission denied" on test_api.sh**
```bash
chmod +x test_api.sh
```

**Courses not saving / JSON decode error**

Delete `courses.json` — it will be recreated fresh on next run:
```bash
rm courses.json
python app.py
```

---

## Understanding the Code

`app.py` is organized into four clear sections:

1. **Imports & config** — Flask setup, DATA_FILE path
2. **Helper functions** — `load_courses()`, `save_courses()`, `get_next_id()`, `find_course_by_id()`, `validate_course_data()`
3. **API endpoints** — one function per route, each with try/except error handling
4. **Error handlers** — catch-all for 404, 405, 500

Every endpoint follows the same pattern:
1. Parse the request
2. Validate the input
3. Load courses from JSON
4. Do the operation (add / find / update / delete)
5. Save back to JSON
6. Return a response

---

## Next Steps (Phase 2 Ideas)

Once you're comfortable with this project, you can extend it by:

- Adding a simple HTML + JavaScript frontend
- Implementing user accounts with authentication
- Migrating from JSON file to a real database (SQLite or PostgreSQL)
- Adding email reminders for approaching target dates
- Deploying to a cloud platform (Heroku, Railway, Render)

---

Built with Python + Flask for learning REST API basics.
