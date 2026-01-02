use anyhow::Result;

pub fn validate_payload(payload: &str) -> Result<()> {
    let blocked = [
        "rm -rf",
        ":(){",
        "shutdown",
        "reboot",
        "mkfs",
        "dd if=",
    ];

    if payload.len() > 5_000 {
        anyhow::bail!("payload too large");
    }

    for bad in blocked {
        if payload.contains(bad) {
            anyhow::bail!("blocked dangerous command");
        }
    }

    Ok(())
}
