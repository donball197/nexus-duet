import sys

file_path = "src/main.rs"

try:
    with open(file_path, "r") as f:
        lines = f.readlines()

    new_lines = []
    for line in lines:
        # 1. Catch the broken "mashed" line and replace it with the 2 correct lines
        if "Arc::clone(let permit" in line or "task_semaphore.acquire()" in line:
            new_lines.append("        let semaphore_clone = Arc::clone(&task_semaphore);\n")
            new_lines.append("        let permit = semaphore_clone.acquire().await.context(\"Failed to acquire semaphore permit\")?;\n")
        # 2. Catch the info! macro line if it's still using the wrong semaphore
        elif "info!(\"Semaphore permit released" in line and "task_semaphore" in line and "semaphore_clone" not in line:
            new_line = line.replace("task_semaphore", "semaphore_clone")
            new_lines.append(new_line)
        else:
            new_lines.append(line)

    with open(file_path, "w") as f:
        f.writelines(new_lines)

    print("✅ src/main.rs has been repaired successfully.")

except Exception as e:
    print(f"❌ Error: {e}")
