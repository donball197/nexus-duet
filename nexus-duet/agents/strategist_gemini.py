import os
import sys
from pathlib import Path
from dotenv import load_dotenv
from google import genai
from google.genai import types

# --- 1. Robust Environment Loading ---
# Try to find athena.env by looking up directory levels
current_dir = Path(__file__).resolve().parent
env_path = None

for i in range(4):  # Check up to 4 levels up
    check_path = current_dir.parents[i] / 'athena.env'
    if check_path.exists():
        env_path = check_path
        break

if env_path:
    load_dotenv(env_path)
    print(f"✅ Loaded environment from: {env_path}")
else:
    print("❌ Could not find athena.env")

# --- 2. Initialize Client ---
api_key = os.getenv("GEMINI_API_KEY")
if not api_key:
    raise ValueError("GEMINI_API_KEY not found in environment variables.")

client = genai.Client(api_key=api_key)

# --- 3. Define the Agent Function ---
def generate_strategy(prompt):
    """
    Generates a strategy response using Gemini 2.5 Flash.
    """
    try:
        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=[prompt],
            config=types.GenerateContentConfig(
                temperature=0.7,
                top_p=0.95,
                top_k=40,
                max_output_tokens=8192,
            )
        )
        return response.text
    except Exception as e:
        return f"Error generating strategy: {e}"

# --- 4. Test Block (Runs only if executed directly) ---
if __name__ == "__main__":
    test_prompt = "Briefly explain the best strategy for deploying a Python app to a VPS."
    print(f"\n🤖 Asking Gemini 2.5-Flash:\n'{test_prompt}'\n")
    
    result = generate_strategy(test_prompt)
    print("-" * 40)
    print(result)
    print("-" * 40)
