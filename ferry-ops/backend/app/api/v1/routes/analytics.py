from fastapi import APIRouter
from app.services.analytics_service import calculate_dummy_kpis

router = APIRouter(prefix="/api/analytics", tags=["analytics"])

@router.get("/kpis")
def kpis():
    return calculate_dummy_kpis()
