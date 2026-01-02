use anyhow::Result;
use tokio::process::Command;
use tokio::time::{timeout, Duration};

pub async fn execute_safe(cmd: &str) -> Result<String> {
    let output = timeout(
        Duration::from_secs(30),
        Command::new("bash")
            .arg("-c")
            .arg(cmd)
            .kill_on_drop(true)
            .output()
    )
    .await
    .map_err(|_| anyhow::anyhow!("execution timed out"))??;

    if !output.status.success() {
        anyhow::bail!(
            "command failed: {}",
            String::from_utf8_lossy(&output.stderr)
        );
    }

    Ok(String::from_utf8_lossy(&output.stdout).to_string())
}
