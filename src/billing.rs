use serde::Serialize;
use std::fs::OpenOptions;
use std::io::Write;
use chrono::Utc;

#[derive(Serialize)]
pub struct BillableEvent {
    pub timestamp: String,
    pub node_id: String,
    pub event_type: String,
    pub cost_units: u32,
}

pub fn log_billable_event(event_type: &str, node_id: &str) {
    let event = BillableEvent {
        timestamp: Utc::now().to_rfc3339(),
        node_id: node_id.to_string(),
        event_type: event_type.to_string(),
        cost_units: 1,
    };
    let _ = std::fs::create_dir_all("workspace/sessions");
    if let Ok(mut file) = OpenOptions::new().create(true).append(true).open("workspace/sessions/billing.log") {
        if let Ok(data) = serde_json::to_string(&event) {
            let _ = writeln!(file, "{}", data);
        }
    }
}
