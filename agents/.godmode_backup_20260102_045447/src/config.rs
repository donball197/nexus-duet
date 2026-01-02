use serde::Deserialize;
use anyhow::{Context, Result};
use std::path::Path;
use url::Url;

/// Represents the agent's configuration loaded from various sources.
#[derive(Debug, Deserialize, Clone)]
pub struct AgentConfig {
    pub agent_id: String,
    pub orchestrator_url: Url,
    #[serde(default = "default_poll_interval")]
    pub poll_interval_seconds: u64,
    #[serde(default = "default_max_concurrent_tasks")]
    pub max_concurrent_tasks: usize,
    // Add more configuration options as needed, e.g.,
    // pub log_level: String,
    // pub auth_token: Option<String>,
}

/// Default value for `poll_interval_seconds`.
fn default_poll_interval() -> u64 {
    5 // seconds
}

/// Default value for `max_concurrent_tasks`.
fn default_max_concurrent_tasks() -> usize {
    2 // tasks
}

impl AgentConfig {
    /// Loads the agent configuration from a specified file, environment variables, and defaults.
    ///
    /// Configuration precedence (highest to lowest):
    /// 1. Environment variables (prefixed with `AGENT_`, e.g., `AGENT_AGENT_ID`)
    /// 2. Configuration file (if `config_path` is provided)
    /// 3. Default values
    pub fn load(config_path: Option<&str>) -> Result<Self> {
        let mut settings = config::Config::builder()
            // 1. Start with default configuration values
            .set_default("agent_id", "default-rust-agent")?
            .set_default("orchestrator_url", "http://localhost:8080")?
            .set_default("poll_interval_seconds", default_poll_interval() as i64)?
            .set_default("max_concurrent_tasks", default_max_concurrent_tasks() as i64)?;

        // 2. Add configuration file if specified
        if let Some(path) = config_path {
            settings = settings.add_source(
                config::File::from(Path::new(path))
                    .required(true) // Make config file mandatory if specified
            );
        }

        // 3. Add environment variables (e.g., AGENT_AGENT_ID, AGENT_ORCHESTRATOR_URL)
        //    Environment variables override file and default settings.
        settings = settings.add_source(
            config::Environment::with_prefix("AGENT")
                .separator("__") // Use double underscore for nested keys (e.g., AGENT_ORCHESTRATOR__URL)
                .ignore_empty(true)
        );

        settings
            .build()?
            .try_deserialize()
            .context("Failed to deserialize agent configuration. Check your config file and environment variables.")
    }
}

