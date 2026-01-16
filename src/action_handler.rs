use std::process::Command;
use std::sync::Arc;
use crate::AppState;

pub async fn execute_directive(_state: Arc<AppState>, raw_command: &str) -> String {
    println!("⚙️  ACTION_HANDLER: Executing [ {} ]", raw_command);
    let output = Command::new("sh").arg("-c").arg(raw_command).output();
    match output {
        Ok(out) => {
            let res = String::from_utf8_lossy(&out.stdout).to_string();
            let err = String::from_utf8_lossy(&out.stderr).to_string();
            format!("{}\n{}", res, err)
        },
        Err(e) => format!("EXECUTION_FAILURE: {}", e),
    }
}

pub async fn restore_last_snapshot() -> String {
    let output = Command::new("sh").arg("-c")
        .arg("ls -t nexus_snapshot_*.tar.gz | head -n 1").output();
    if let Ok(out) = output {
        let filename = String::from_utf8_lossy(&out.stdout).trim().to_string();
        if filename.is_empty() { return "FAILURE: No snapshots found.".to_string(); }
        let res = Command::new("tar").arg("-xzf").arg(&filename).output();
        match res {
            Ok(_) => format!("SUCCESS: Restored from {}", filename),
            Err(e) => format!("FAILURE: Extraction failed: {}", e),
        }
    } else { "FAILURE: Access denied.".to_string() }
}

pub fn parse_action(text: &str) -> Option<&str> {
    if let Some(start) = text.find("[SHELL]") {
        if let Some(end) = text.find("[/SHELL]") {
            return Some(&text[start + 7..end].trim());
        }
    }
    None
}

pub async fn git_commit(message: &str) -> String {
    let output = Command::new("sh")
        .arg("-c")
        .arg(format!("git add . && git commit -m '{}'", message))
        .output();

    match output {
        Ok(out) => {
            let res = String::from_utf8_lossy(&out.stdout).to_string();
            let err = String::from_utf8_lossy(&out.stderr).to_string();
            format!("GIT_COMMIT:\n{}\n{}", res, err)
        },
        Err(e) => format!("GIT_FAILURE: {}", e),
    }
}
