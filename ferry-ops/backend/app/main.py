from fastapi import FastAPI
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from app.core.config import settings
from app.db.init_db import init_db

app = FastAPI(title=settings.APP_NAME, version=settings.APP_VERSION)
app.mount("/static", StaticFiles(directory="static"), name="static")

@app.on_event("startup")
def startup():
    init_db()

@app.get("/", response_class=HTMLResponse)
def home():
    return """
    <!doctype html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>Ferry Ops</title>
      <style>
        body{font-family:Arial;margin:40px;background:#f5f7fb}
        .box{max-width:900px;margin:auto;background:#fff;padding:24px;border-radius:16px}
      </style>
    </head>
    <body>
      <div class="box">
        <h1>Ferry Operations Platform</h1>
        <p>Part 1 running successfully.</p>
      </div>
    </body>
    </html>
    """
