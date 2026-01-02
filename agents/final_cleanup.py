import sys

path = "src/main.rs"

with open(path, "r") as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    # 1. Remove manual drops of the missing 'permit' variable
    if "drop(permit);" in line:
        continue
        
    # 2. Remove assignments trying to move the missing 'permit'
    # Matches things like "let permit_clone = permit;" or similar
    if " = permit;" in line or " = permit " in line:
        continue

    # 3. Clean up the unused import warning
    if "use anyhow::Context;" in line:
        continue

    new_lines.append(line)

with open(path, "w") as f:
    f.writelines(new_lines)

print("✅ Cleanup complete: Removed leftover references to 'permit'.")
