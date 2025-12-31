import os
import sys
from pathlib import Path
from dotenv import load_dotenv
from google import genai
from google.genai import types

# --- 1. Robust Environment Loading ---
current_dir = Path(__file__).resolve().parent
env_path = None

for i in range(4):
    check_path = current_dir.parents[i] / 'athena.env'
    if check_path.exists():
        env_path = check_path
        break

if env_path:
    load_dotenv(env_path)
else:
    print("❌ [Coder] Could not find athena.env")

# --- 2. Initialize Client ---
api_key = os.getenv("GEMINI_API_KEY")
if not api_key:
    raise ValueError("GEMINI_API_KEY not found.")

client = genai.Client(api_key=api_key)

# --- 3. Define the Agent Function ---
def generate_code(task, strategy_context=None):
    """
    Generates code using Gemini 2.5 Flash with strict formatting instructions.
    """
    
    base_prompt = f"You are an expert software engineer. Write clean, efficient code for the following task:\n\nTASK:\n{task}"
    
    if strategy_context:
        base_prompt += f"\n\nSTRATEGIC CONTEXT:\n{strategy_context}"
        
    base_prompt += """
    
    IMPORTANT OUTPUT FORMAT:
    For every file you generate, you must use this exact format:

    ### FILE: path/to/filename.ext
    ```language
    file_content_here
    ```

    Example:
    ### FILE: main.py
    ```python
    print("Hello")
    ```

    - Do not include any text outside of these file blocks.
    - Ensure all code is complete (no placeholders like '...').
    - Include a 'requirements.txt' if external libraries are needed.
    """

    try:
        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=[base_prompt],
            config=types.GenerateContentConfig(
                temperature=0.2,
                top_p=0.95,
                top_k=40,
                max_output_tokens=8192,
            )
        )
        return response.text
    except Exception as e:
        return f"Error generating code: {e}"

# --- 4. Test Block ---
if __name__ == "__main__":
    test_task = "Create a simple Python script called hello.py that prints 'Hello World'"
    print(f"\n💻 Coder Agent working on:\n'{test_task}'\n")
    result = generate_code(test_task)
    print(result)
