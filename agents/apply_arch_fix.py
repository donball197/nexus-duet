import sys

def fix_rust_files():
    # --- Fix 1: src/main.rs (Move semaphore inside spawn) ---
    main_path = "src/main.rs"
    with open(main_path, "r") as f:
        lines = f.readlines()

    new_lines = []
    for line in lines:
        # DELETE the bad "outer" acquire we added earlier
        if "semaphore_clone.acquire()" in line and "tokio::spawn" not in line:
            continue
            
        # Add the line to the file
        new_lines.append(line)

        # INJECT the good "inner" acquire right after the task starts
        if "tokio::spawn(async move {" in line:
            new_lines.append("            // ✅ FIXED: Acquire permit inside the task\n")
            new_lines.append("            let _permit = semaphore_clone.acquire().await.unwrap();\n")
            new_lines.append("            info!(\"Task started. Permits left: {}\", semaphore_clone.available_permits());\n")

    with open(main_path, "w") as f:
        f.writelines(new_lines)
    print("✅ src/main.rs repaired.")

    # --- Fix 2: src/communication.rs (Clean imports) ---
    comm_path = "src/communication.rs"
    try:
        with open(comm_path, "r") as f:
            content = f.read()
        
        # Remove unused imports
        content = content.replace("use tracing::{error, info, instrument};", "use tracing::{info, instrument};")
        content = content.replace("use std::sync::Arc;", "")
        content = content.replace("use serde::{Deserialize, Serialize};", "use serde::Serialize;") 

        with open(comm_path, "w") as f:
            f.write(content)
        print("✅ src/communication.rs cleaned.")
    except FileNotFoundError:
        print("⚠️  src/communication.rs not found, skipping.")

if __name__ == "__main__":
    fix_rust_files()
