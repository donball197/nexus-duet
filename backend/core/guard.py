# backend/core/guard.py

def check_safety(prompt: str) -> bool:
    """Return False if prompt is unsafe."""
    blocked_words = ["hack", "malware", "exploit"]
    return not any(word in prompt.lower() for word in blocked_words)

def local_think(prompt: str) -> str:
    """Return system context or processing for prompt."""
    return "System ready. Processing prompt."
