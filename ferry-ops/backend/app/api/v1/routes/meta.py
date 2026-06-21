from fastapi import APIRouter
from app.core.config import settings

router = APIRouter(prefix="/api/meta", tags=["meta"])

@router.get("/info")
def info():
    return {
        "app_name": settings.APP_NAME,
        "version": settings.APP_VERSION
    }
