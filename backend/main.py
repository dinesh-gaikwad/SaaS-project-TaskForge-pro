from fastapi import FastAPI

app = FastAPI(
    title="TaskForge AI Pro",
    version="1.0.0"
)

@app.get("/")
def home():
    return {
        "message": "TaskForge AI Pro Running"
    }

@app.get("/health")
def health():
    return {
        "status": "healthy"
    }
