import sys
import os
import time
import re
import json
import datetime
from pathlib import Path

# Ensure we can import from the agents folder
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

try:
    from agents.strategist_gemini import generate_strategy
    from agents.coder_gemini import generate_code
except ImportError as e:
    print(f"❌ Import Error: {e}")
    sys.exit(1)

# --- MEMORY SYSTEM ---
MEMORY_DIR = Path("memory")
MEMORY_DIR.mkdir(exist_ok=True)
MEMORY_FILE = MEMORY_DIR / "nexus_history.json"

def save_memory(objective, strategy, code, project_name):
    entry = {
        "timestamp": datetime.datetime.now().isoformat(),
        "project_name": project_name,
        "objective": objective,
        "strategy": strategy,
        "code_raw": code
    }
    
    # Load existing memory
    history = []
    if MEMORY_FILE.exists():
        try:
            with open(MEMORY_FILE, "r") as f:
                history = json.load(f)
        except:
            history = []
    
    history.append(entry)
    
    with open(MEMORY_FILE, "w") as f:
        json.dump(history, f, indent=2)

# --- GOD MODE GENERATOR ---
def generate_installer_script(code_output):
    """
    Parses the LLM output and creates a single Bash script
    that automates the entire creation process.
    """
    # 1. Parse files from the LLM output
    # Regex looks for ### FILE: filename, then captures the content inside code blocks
    file_pattern = re.compile(r'### FILE: (.*?)\n.*?```.*?\n(.*?)```', re.DOTALL)
    files = []
    
    for match in file_pattern.finditer(code_output):
        filepath = match.group(1).strip()
        content = match.group(2)
        files.append((filepath, content))

    if not files:
        print("⚠️  No files detected in LLM output. Cannot generate installer.")
        return None

    # 2. Build the Bash Script Content
    script_content = [
        "#!/bin/bash",
        "set -e", # Exit on error
        "",
        "echo '🚀 NEXUS GOD MODE: Initializing Deployment...'",
        "echo '--------------------------------------------'",
        "",
        "# 1. Ask User for Project Name",
        "read -p 'Enter name for this project (folder name): ' PROJ_NAME",
        "if [ -z \"$PROJ_NAME\" ]; then",
        "  PROJ_NAME=\"nexus_project\"",
        "fi",
        "",
        "echo \"📂 Creating project directory: $PROJ_NAME\"",
        "mkdir -p \"$PROJ_NAME\"",
        "cd \"$PROJ_NAME\"",
        "",
        "echo '📝 Writing files...'"
    ]

    for filepath, content in files:
        # Determine subdirectory (e.g., templates/) and add mkdir command
        dir_name = os.path.dirname(filepath)
        if dir_name:
            script_content.append(f"mkdir -p \"{dir_name}\"")
        
        # Use a safe heredoc delimiter. 
        # We wrap EOF in single quotes ('EOF') so variables inside code ($VAR) are NOT expanded by bash.
        script_content.append(f"cat << 'EOF_NEXUS' > \"{filepath}\"")
        script_content.append(content) # Insert the raw code
        script_content.append("EOF_NEXUS")
        script_content.append(f"echo '  - Created: {filepath}'")
        script_content.append("")

    # 3. Add Environment Setup Logic
    script_content.extend([
        "echo '--------------------------------------------'",
        "echo '⚙️  Setting up Environment...'",
        "",
        "# Check if requirements.txt exists",
        "if [ -f requirements.txt ]; then",
        "    if [ ! -d 'venv' ]; then",
        "        echo '  - Creating Python Virtual Environment (venv)...'",
        "        python3 -m venv venv",
        "    fi",
        "    echo '  - Installing dependencies...'",
        "    ./venv/bin/pip install --upgrade pip",
        "    ./venv/bin/pip install -r requirements.txt",
        "else",
        "    echo '⚠️  No requirements.txt found. Skipping dependency install.'",
        "fi",
        "",
        "echo '--------------------------------------------'",
        "echo '✅ Deployment Complete!'",
        "echo 'To run your project:'",
        "echo \"  cd $PROJ_NAME\"",
        "echo '  source venv/bin/activate'",
        "echo '  python app.py (or your main script)'",
        "echo '--------------------------------------------'",
        "",
        "# Optional: Ask to run immediately",
        "read -p 'Do you want to attempt to run the project now? (y/n): ' RUN_NOW",
        "if [[ \"$RUN_NOW\" =~ ^[Yy]$ ]]; then",
        "    if [ -f app.py ]; then",
        "        ./venv/bin/python app.py",
        "    elif [ -f main.py ]; then",
        "        ./venv/bin/python main.py",
        "    else",
        "        echo '❌ Could not find app.py or main.py to run automatically.'",
        "    fi",
        "fi"
    ])

    return "\n".join(script_content)

def run_duet(user_objective):
    print("\n" + "="*60)
    print(f"🚀 NEXUS DUET STARTED")
    print(f"🎯 Objective: {user_objective}")
    print("="*60 + "\n")

    # --- Phase 1: Strategy ---
    print("🧠 Strategist Agent is analyzing...")
    strategy = generate_strategy(user_objective)
    print("✅ Strategy secured.")

    # --- Phase 2: Coding ---
    print("💻 Coder Agent is building architecture...")
    # Passing the objective + strategy to the coder
    code_output = generate_code(user_objective, strategy_context=strategy)
    print("✅ Code generated.")

    # --- Phase 3: God Mode Generation ---
    installer_script = generate_installer_script(code_output)
    
    if installer_script:
        script_name = "deploy_nexus.sh"
        with open(script_name, "w") as f:
            f.write(installer_script)
        
        # Make it executable
        os.chmod(script_name, 0o755)
        
        print("\n" + "="*60)
        print(f"🔥 GOD MODE SCRIPT GENERATED: ./{script_name}")
        print("="*60)
        print(f"To build '{user_objective}', simply run:")
        print(f"  ./{script_name}")
        
        # Save to Memory
        save_memory(user_objective, strategy, code_output, "deploy_nexus")
    else:
        print("❌ Failed to generate installer script (No file blocks found).")
        # Save debug info
        with open("debug_output.txt", "w") as f:
            f.write(code_output)
        print("Debug output saved to debug_output.txt")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        objective = " ".join(sys.argv[1:])
    else:
        print("Enter your goal:")
        objective = input("nexus-duet > ")
    
    if objective.strip():
        run_duet(objective)
