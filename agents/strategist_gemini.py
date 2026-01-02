import os
from dotenv import load_dotenv
from google import genai
from google.genai import types

load_dotenv("athena.env")
api_key = os.getenv("GEMINI_API_KEY")
client = genai.Client(api_key=api_key)

def generate_strategy(prompt):
    try:
        response = client.models.generate_content(
            model="gemini-2.5-flash", contents=[prompt],
            config=types.GenerateContentConfig(temperature=0.7)
        )
        return response.text
    except Exception as e: return f"Error: {e}"
