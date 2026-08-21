from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List

app = FastAPI(title="AI StudySync 2027", version="1.0.0")

groups = [
    {"id": 1, "name": "Calculus 101", "members": 18, "topic": "Mathematics"},
    {"id": 2, "name": "Python AI Lab", "members": 27, "topic": "AI / ML"},
]
resources = [
    {"id": 1, "group_id": 1, "title": "Limits & Derivatives Notes", "type": "PDF"},
    {"id": 2, "group_id": 2, "title": "Python Interview Cheatsheet", "type": "PDF"},
]
quizzes = [
    {"id": 1, "title": "Python Basics", "questions": 10, "best_score": 92},
    {"id": 2, "title": "Calculus Sprint", "questions": 15, "best_score": 88},
]
tutors = [
    {"id": 1, "name": "Aarav Sharma", "skill": "Python & AI", "rate": 18},
    {"id": 2, "name": "Maya Patel", "skill": "Mathematics", "rate": 15},
]

class GroupIn(BaseModel):
    name: str
    topic: str

class ChatIn(BaseModel):
    user: str
    message: str

chat: List[dict] = []

@app.get("/")
def root():
    return {"project": "AI StudySync 2027", "status": "running"}

@app.get("/api/dashboard")
def dashboard():
    return {
        "groups": len(groups),
        "resources": len(resources),
        "quizzes": len(quizzes),
        "tutors": len(tutors),
        "study_hours": 42
    }

@app.get("/api/groups")
def get_groups():
    return groups

@app.post("/api/groups")
def create_group(data: GroupIn):
    item = {"id": len(groups)+1, "name": data.name, "members": 1, "topic": data.topic}
    groups.append(item)
    return item

@app.get("/api/resources")
def get_resources():
    return resources

@app.get("/api/quizzes")
def get_quizzes():
    return quizzes

@app.get("/api/tutors")
def get_tutors():
    return tutors

@app.get("/api/chat")
def get_chat():
    return chat[-50:]

@app.post("/api/chat")
def send_chat(data: ChatIn):
    item = {"user": data.user, "message": data.message}
    chat.append(item)
    return item

@app.post("/api/whiteboard/event")
def whiteboard_event(payload: dict):
    return {"accepted": True, "event": payload}
