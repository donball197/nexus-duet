use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use tokio::process::Command;
use tracing::{error, info, instrument};
use std::collections::HashMap;
use std::time::Instant;

/// Represents a task received from the orchestrator.
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct Task {
    pub id: String,
    pub task_type: String, // e.g., "shell_command", "docker_build", "file_transfer"
    pub command: String,   // The executable or script to run
    pub args: Vec<String>, // Arguments for the command
    pub environment: Option<HashMap<String, String>>, // Environment variables for the task
    pub working_directory: Option<String>, // Directory to execute the command in
    // Add more task-specific parameters as needed (e.g., timeout, artifact paths)
}

/// Represents the result of an executed task.
#[derive(Debug, Serialize, Deserialize)]
pub struct TaskResult {
    pub task_id: String,
    pub status: String, // "SUCCESS", "FAILED", "TIMEOUT", etc.
    pub stdout: String,
    pub stderr: String,
    pub exit_code: Option<i32>,
    pub duration_ms: u64,
    // Add more result details like metrics, artifact paths, etc.
}

/// Executes a given task by spawning a child process.
///
/// This function is instrumented with `tracing` to provide detailed logs.
#[instrument(skip(task), fields(task_id = %task.id, task_type = %task.task_type))]
pub async fn execute_task(task: Task) -> Result<TaskResult> {
    info!("Starting execution of task: {}", task.id);
    let start_time = Instant::now();

    // Create a new command builder
    let mut command = Command::new(&task.command);
    command.args(&task.args);

    // Set environment variables if provided
    if let Some(env) = &task.environment {
        command.envs(env);
    }
    // Set working directory if provided
    if let Some(cwd) = &task.working_directory {
        command.current_dir(cwd);
    }

    // Execute the command and wait for its output
    let output = command
        .output()
        .await
        .context(format!("Failed to execute command '{}' with args '{:?}'", task.command, task.args))?;

    // Capture stdout and stderr
    let stdout = String::from_utf8_lossy(&output.stdout).into_owned();
    let stderr = String::from_utf8_lossy(&output.stderr).into_owned();
    let exit_code = output.status.code();

    // Determine task status based on exit code
    let status = if output.status.success() {
        "SUCCESS".to_string()
    } else {
        error!("Task {} failed with exit code: {:?}. Stderr: {}", task.id, exit_code, stderr);
        "FAILED".to_string()
    };

    let duration = start_time.elapsed();

    info!("Task {} finished. Status: {}. Duration: {}ms", task.id, status, duration.as_millis());

    Ok(TaskResult {
        task_id: task.id,
        status,
        stdout,
        stderr,
        exit_code,
        duration_ms: duration.as_millis() as u64,
    })
}

