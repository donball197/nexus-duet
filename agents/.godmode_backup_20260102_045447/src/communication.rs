use anyhow::{Context, Result};
use reqwest::{Client, Url};
use serde::Serialize;
use tracing::{info, instrument, error};
use crate::task_executor::{Task, TaskResult};

#[derive(Debug, Clone)]
pub struct OrchestratorClient {
    client: Client,
    orchestrator_base_url: Url,
    agent_id: String,
}

impl OrchestratorClient {
    pub fn new(base_url: &Url, agent_id: &str) -> Result<Self> {
        let client = Client::builder().build().context("Failed to build HTTP client")?;
        Ok(Self {
            client,
            orchestrator_base_url: base_url.clone(),
            agent_id: agent_id.to_string(),
        })
    }

    /// Polls the orchestrator for new tasks.
    #[instrument(skip(self))]
    pub async fn poll_for_task(&self) -> Result<Option<Task>> {
        // Construct the URL. IMPORTANT: Matches Backend route structure
        let url = self.orchestrator_base_url.join(&format!("agent/{}/tasks/poll", self.agent_id))?;
        
        // Actually talk to the server
        let response = self.client.post(url.clone()).send().await;

        match response {
            Ok(resp) => {
                if resp.status().is_success() {
                    // If we get a 200 OK, parse the Task
                    let task = resp.json::<Task>().await.ok();
                    if task.is_some() {
                        info!("🚀 Task successfully downloaded from Backend!");
                    }
                    Ok(task)
                } else {
                    // 204 No Content or 404 means "No work for you yet"
                    Ok(None)
                }
            }
            Err(e) => {
                error!("❌ Connection Error (Is Backend running?): {}", e);
                Ok(None)
            }
        }
    }

    #[instrument(skip(self))]
    pub async fn report_task_status(&self, task_id: &str, status: &str) -> Result<()> {
        let url = self.orchestrator_base_url.join(&format!("agent/{}/tasks/{}/status", self.agent_id, task_id))?;
        
        #[derive(Serialize)]
        struct StatusUpdate<'a> { status: &'a str }

        let _ = self.client.post(url)
            .json(&StatusUpdate { status })
            .send()
            .await?;
        Ok(())
    }

    #[instrument(skip(self, result))]
    pub async fn report_task_result(&self, task_id: &str, result: TaskResult) -> Result<()> {
        let url = self.orchestrator_base_url.join(&format!("agent/{}/tasks/{}/result", self.agent_id, task_id))?;
        
        let _ = self.client.post(url)
            .json(&result)
            .send()
            .await?;
        Ok(())
    }
}
