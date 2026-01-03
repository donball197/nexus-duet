from google import genai
import os
from dotenv import load_dotenv

load_dotenv('athena.env')
api_key = os.getenv("GEMINI_API_KEY")
client = genai.Client(api_key=api_key)

print("Available Gemini Models:")
for model in client.models.list():
    if "generateContent" in model.supported_actions:
        print(f"Model Name: {model.name}")
        print(f"Display Name: {model.display_name}")
        print(f"Context Window: {model.input_token_limit} tokens\n")
