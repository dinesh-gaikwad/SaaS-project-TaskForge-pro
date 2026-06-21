from datetime import datetime

def format_alert(level: str, message: str) -> str:
    return f"[{level.upper()}] {message} @ {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
