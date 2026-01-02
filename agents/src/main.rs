use serde::{Deserialize, Serialize};
use std::time::Duration;
use tokio::time::sleep;
use reqwest::Client;
use rand::prelude::*; // Required for thread_rng() and gen()

#[derive(Serialize, Deserialize, Debug)]
struct Task {
    id: String,
    payload: String,
    attempts: i32,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let agent_id = "agent-3ce30b62";
    let client = Client::builder().timeout(Duration::from_secs(5)).build()?;

    println!("🛡️ Chaos Agent {} Online (100% Success Rate).", agent_id);

    loop {
        let _ = client.get("http://127.0.0.1:118080/health").send().await;

        if let Ok(res) = client.get("http://127.0.0.1:118080/next_task").send().await {
            if let Ok(Some(task)) = res.json::<Option<Task>>().await {
                println!("📦 Task received: {}", task.payload);

                // Probabilistic Decision
                let success_roll: f64 = thread_rng().gen();
                
                if success_roll < 1.0 {
                    let ok_url = format!("http://127.0.0.1:118080/complete_task/{}", task.id);
                    let _ = client.post(ok_url).send().await;
                    println!("✅ Task {} completed successfully!", task.id);
                } else {
                    let fail_url = format!("http://127.0.0.1:118080/fail_task/{}", task.id);
                    let _ = client.post(fail_url).send().await;
                    println!("❌ Task {} failed. Retrying later...", task.id);
                }
            }
        }
        sleep(Duration::from_secs(3)).await;
    }
}

