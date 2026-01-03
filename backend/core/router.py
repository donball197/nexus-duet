import os
from google import genai
from tenacity import retry, stop_after_attempt, wait_exponential
from PIL import Image

# THE FIX: Use absolute import 'core.guard', not '.guard'
from core.guard import check_safety, local_think

MODEL_CASCADE = ["gemini-3-pro-preview", "gemini-2.5-pro", "gemini-2.5-flash"]

class SmartRouter:
    def __init__(self):
        key = os.environ.get("GOOGLE_API_KEY")
        if not key: raise ValueError("GOOGLE_API_KEY missing")
        self.client = genai.Client(api_key=key)

    @retry(stop=stop_after_attempt(3), wait=wait_exponential(min=2, max=10))
    def generate(self, prompt, image_path=None):
        if not check_safety(prompt): return "🛡️ BLOCKED: T3 Rust Guard detected hazard."
        local_ctx = local_think(prompt)
        inputs = [f"System Context: {local_ctx}\nUser: {prompt}"]
        if image_path and os.path.exists(image_path): inputs.append(Image.open(image_path))
        last_err = None
        for m in MODEL_CASCADE:
            try:
                res = self.client.models.generate_content(model=m, contents=inputs)
                return f"[{m}] {res.text}"
            except Exception as e: last_err = e
        raise last_err
