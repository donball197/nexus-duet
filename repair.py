import os

# Create directory
os.makedirs("agents", exist_ok=True)
with open("agents/__init__.py", "w") as f:
    f.write("")

# Write Strategist Agent
with open("agents/strategist_gemini.py", "w") as f:
    f.write('''import os
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
''')

# Write Coder Agent
with open("agents/coder_gemini.py", "w") as f:
    f.write('''import os
from dotenv import load_dotenv
from google import genai
from google.genai import types

load_dotenv("athena.env")
api_key = os.getenv("GEMINI_API_KEY")
client = genai.Client(api_key=api_key)

def generate_code(task, strategy_context=None):
    prompt = f"Task: {task}\\nContext: {strategy_context}\\n"
    prompt += "Output format:\\n### FILE: filename\\n```\\ncode\\n```"
    try:
        response = client.models.generate_content(
            model="gemini-2.5-flash", contents=[prompt],
            config=types.GenerateContentConfig(temperature=0.2)
        )
        return response.text
    except Exception as e: return f"Error: {e}"
''')

print("✅ Agents successfully repaired!")
