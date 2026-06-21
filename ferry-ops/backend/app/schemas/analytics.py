from pydantic import BaseModel

class KPIData(BaseModel):
    bounce_rate: float
    avg_session_duration: float
    mobile_usage_percent: float
    search_success_rate: float
