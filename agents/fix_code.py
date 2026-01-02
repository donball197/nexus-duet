import sys

file_path = "src/main.rs"

try:
    with open(file_path, "r") as f:
        lines = f.readlines()

    new_lines = []
    for line in lines:
        # Detect the mashed line from the bad sed command
        if "Arc::clone(let permit" in line or "acquire()task_semaphore" in line:
            new_lines.append("        let semaphore_clone = Arc::clone(&task_semaphore);\n")
            new_lines.append("        let permit = semaphore_clone.acquire().await.context(\"Failed to acquire semaphore permit\")?;\n")
        
        # Fix the logging line to use the clone instead of the original
        elif "info!(\"Semaphore permit released" in line and "task_semaphore" in line:
            new_lines.append(line.replace("task_semaphore", "semaphore_clone"))
            
        else:
            new_lines.append(line)

    with open(file_path, "w") as f:
        f.writelines(new_lines)

    print("✅ src/main.rs has been repaired successfully.")

except Exception as e:
    print(f"❌ Error: {e}")
