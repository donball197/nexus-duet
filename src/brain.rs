use crate::AppState;
use crate::action_handler;
use axum::response::sse::Event;
use futures_util::StreamExt;
use serde_json::json;
use std::sync::Arc;

pub fn process_stream(state: Arc<AppState>, prompt: String) -> impl futures_util::Stream<Item = Result<Event, std::convert::Infallible>> {
    async_stream::stream! {
        let api_key = std::env::var("GEMINI_API_KEY").unwrap_or_default();
        let url = format!("https://generativelanguage.googleapis.com/v1beta/models/gemma-3-27b-it:streamGenerateContent?alt=sse&key={}", api_key);
        let sys_msg = "You are GUARDIAN 734. You have shell access. Use [SHELL]command[/SHELL] to act. Concise only.";
        let body = json!({"contents": [{"parts": [{"text": format!("{}\nUSER: {}", sys_msg, prompt)}]}]});

        if let Ok(res) = state.client.post(&url).json(&body).send().await {
            let mut byte_stream = res.bytes_stream();
            let mut full_resp = String::new();
            while let Some(Ok(bytes)) = byte_stream.next().await {
                let text = String::from_utf8_lossy(&bytes);
                for line in text.lines().filter(|l| l.starts_with("data: ")) {
                    let json_str = &line[6..].trim();
                    if *json_str == "[DONE]" { break; }
                    if let Ok(j) = serde_json::from_str::<serde_json::Value>(json_str) {
                        if let Some(chunk) = j["candidates"][0]["content"]["parts"][0]["text"].as_str() {
                            full_resp.push_str(chunk);
                            yield Ok(Event::default().data(chunk));
                        }
                    }
                }
            }
            if let Some(cmd) = action_handler::parse_action(&full_resp) {
                let output = action_handler::execute_directive(state.clone(), cmd).await;
                yield Ok(Event::default().data(format!("\n[TOOL_OUTPUT]:\n{}", output)));
            }
        }
    }
}
