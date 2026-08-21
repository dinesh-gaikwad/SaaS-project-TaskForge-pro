# AI StudySync 2027 — Project #2

A portfolio-ready collaborative learning platform foundation.

## Features
- Study group creation and membership
- Shared resource metadata
- Real-time Socket.IO-style chat architecture
- Collaborative whiteboard event model
- Quiz/flashcard API
- Leaderboard
- Tutor marketplace and booking model
- Responsive dashboard UI
- SQLite demo database
- Tests and Docker configuration

## Run
Backend:
```bash
cd backend
python -m venv .venv
# Windows: .venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Frontend:
```bash
python -m http.server 5501 --directory frontend
```

Open http://127.0.0.1:5501 and backend API at http://127.0.0.1:8000/docs.

This version uses local demo data. For production, add MongoDB/PostgreSQL, S3, real authentication, Socket.IO server, WebRTC provider, and background jobs.
