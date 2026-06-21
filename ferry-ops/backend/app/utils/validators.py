def clean_text(value: str) -> str:
    return (value or "").strip()

def is_positive_int(value: int) -> bool:
    return isinstance(value, int) and value > 0
