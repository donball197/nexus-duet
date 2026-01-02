use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::time::Duration;
use tokio::sync::{mpsc, Semaphore};
use std::sync::Arc;
use uuid::Uuid;

#[derive(Serialize, Deserialize, Debug)]
struct Task {
    id: String,
    #[serde(rename = "type_field")]
    type_field: String,
    payload: String,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let client = Client::new();
    let agent_id = format!("agent-{}", &Uuid::new_v4().to_string()[..8]);
    let (tx, mut rx) = mpsc::channel::<Task>(100);
    let semaphore = Arc::new(Semaphore::new(1));

    println!("🛡️ Event-Driven Agent {} Online.", agent_id);

    // 1. SILENT POLLER (Uses its own clone of IDs)
    let poll_client = client.clone();
    let poll_id = agent_id.clone();
    tokio::spawn(async move {
        loop {
            let url = format!("http://localhost:8080/agent/{}/poll", poll_id);
            if let Ok(resp) = poll_client.post(&url).send().await {
                if let Ok(Some(task)) = resp.json::<Option<Task>>().await {
                    let _ = tx.send(task).await;
                }
            }
            tokio::time::sleep(Duration::from_secs(2)).await;
        }
    });

    // 2. HEARTBEAT (Uses its own clone of IDs)
    let hb_client = client.clone();
    let hb_id = agent_id.clone();
    tokio::spawn(async move {
        loop {
            tokio::time::sleep(Duration::from_secs(10)).await;
            let url = format!("http://localhost:8080/agent/{}/heartbeat", hb_id);
            let _ = hb_client.post(&url).send().await;
            println!("💤 Agent {} heartbeat sent", hb_id);
        }
    });

    // 3. EXECUTION LOOP
    while let Some(task) = rx.recv().await {
        let permit = semaphore.clone().acquire_owned().await.unwrap();
        println!("⚡ Starting Task: {}", task.id);

        tokio::spawn(async move {
            // Task execution logic
            tokio::time::sleep(Duration::from_secs(2)).await;
            println!("✅ Task Completed: {}", task.id);
            drop(permit);
        });
    }
    Ok(())
}
