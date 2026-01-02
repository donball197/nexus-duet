import sys
import os
import re
from dotenv import load_dotenv
from google import genai
from google.genai import types

# --- 1. SETUP & AUTH ---
load_dotenv('athena.env')
api_key = os.getenv("GEMINI_API_KEY")

if not api_key:
    print("❌ ERROR: GEMINI_API_KEY not found in athena.env")
    sys.exit(1)

client = genai.Client(api_key=api_key)

# --- 2. INTERNAL AGENTS (No external files needed) ---
def generate_strategy(prompt):
    try:
        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=[f"Create a technical strategy for: {prompt}"],
            config=types.GenerateContentConfig(temperature=0.7)
        )
        return response.text
    except Exception as e:
        return f"Error: {e}"

def generate_code(task, strategy):
    prompt = f"Act as an expert developer.\nTask: {task}\nStrategy: {strategy}\n"
    prompt += "IMPORTANT: Return code in this format only:\n"
    prompt += "### FILE: filename.ext\n```language\ncode\n```\n"
    prompt += "Ensure requirements.txt is included if needed."
    
    try:
        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=[prompt],
            config=types.GenerateContentConfig(temperature=0.2)
        )
        return response.text
    except Exception as e:
        return f"Error: {e}"

# --- 3. GOD MODE GENERATOR ---
def generate_installer(code_output, project_name="nexus_app"):
    file_pattern = re.compile(r'### FILE: (.*?)\n.*?```.*?\n(.*?)```', re.DOTALL)
    files = []
    for match in file_pattern.finditer(code_output):
        files.append((match.group(1).strip(), match.group(2)))

    if not files:
        print("⚠️  No files generated. Check API Key or Quota.")
        return None

    script = [
        "#!/bin/bash", "set -e",
        f"PROJ_NAME={project_name}",
        "mkdir -p \"$PROJ_NAME\"", "cd \"$PROJ_NAME\""
    ]

    for filepath, content in files:
        if os.path.dirname(filepath):
            script.append(f"mkdir -p \"{os.path.dirname(filepath)}\"")
        if "allow_unsafe_werkzeug" in content:
            content = content.replace(", allow_unsafe_werkzeug=True", "")
        script.append(f"cat << 'EOF_NEXUS' > \"{filepath}\"\n{content}\nEOF_NEXUS")

    script.append("echo '✅ Project created in '$PROJ_NAME")
    return "\n".join(script)

# --- 4. MAIN EXECUTION ---
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 main.py 'Your Idea'")
        sys.exit(1)
        
    objective = sys.argv[1]
    print(f"🚀 Working on: {objective}")
    
    print("🧠 Strategizing...")
    strategy = generate_strategy(objective)
    
    print("💻 Coding...")
    code = generate_code(objective, strategy)
    
    # Create safe folder name
    safe_name = re.sub(r'\W+', '_', objective.split()[-1].lower())
    
    script = generate_installer(code, safe_name)
    
    if script:
        with open("deploy_nexus.sh", "w") as f:
            f.write(script)
        os.chmod("deploy_nexus.sh", 0o755)
        print("🔥 DONE! Run: ./deploy_nexus.sh")
