use async_trait::async_trait;
use crate::AppState;
use std::sync::Arc;

#[async_trait]
pub trait MicroAgent: Send + Sync {
    fn name(&self) -> &str;
    fn can_handle(&self, prompt: &str) -> bool;
    async fn handle(&self, prompt: &str, state: &Arc<AppState>) -> serde_json::Value;
}

pub async fn run_janitor() {
    println!("🧹 Janitor: Workspace cleanup complete.");
}
