use warp::Filter;
use serde::{Deserialize, Serialize};
use sqlx::{PgPool, Row}; 
use std::env;

#[derive(Deserialize)]
struct ChatRequest { prompt: String, user_id: String }
#[derive(Serialize)]
struct ChatResponse { response: String }

// 1. LOCAL BRAIN (Your Custom Trained GGUF)
async fn call_local_brain(prompt: &str) -> String {
    let client = reqwest::Client::new();
    let ollama_url = env::var("OLLAMA_HOST").unwrap_or("http://ollama:11434".to_string());
    let url = format!("{}/api/generate", ollama_url);
    // Point this to your custom model name after you import it
    let body = serde_json::json!({ "model": "my-custom-model", "prompt": prompt, "stream": false });

    match client.post(&url).json(&body).send().await { 
        Ok(res) => {
            let json: serde_json::Value = res.json().await.unwrap_or_default();
            json["response"].as_str().unwrap_or("Local Brain Offline").to_string()
        },
        Err(_) => "Local Connection Error".to_string()
    }
}

// 2. CLOUD BRAIN (Gemini 3 PRO - Student Edition)
async fn call_google_gemini(prompt: &str) -> String {
    let api_key = env::var("GEMINI_API_KEY").unwrap_or_default();
    if api_key.is_empty() { return "Error: No Gemini API Key found.".to_string(); }
    let client = reqwest::Client::new();
    
    // 🚀 USING GEMINI 3 PRO (The most powerful model you have access to)
    let url = format!("https://generativelanguage.googleapis.com/v1beta/models/gemini-3-pro-preview:generateContent?key={}", api_key);
    
    let body = serde_json::json!({ "contents": [{ "parts": [{ "text": prompt }] }] });

    match client.post(&url).json(&body).send().await {
        Ok(res) => {
            let json: serde_json::Value = res.json().await.unwrap_or_default();
            if let Some(text) = json["candidates"][0]["content"]["parts"][0]["text"].as_str() {
                text.to_string()
            } else {
                format!("Gemini 3 Pro Error: {}", json)
            }
        },
        Err(e) => format!("Cloud Connection Error: {}", e)
    }
}

async fn handle_chat(req: ChatRequest, pool: PgPool) -> Result<impl warp::Reply, warp::Rejection> {
    let p_low = req.prompt.to_lowercase();

    // ROUTE A: PRIVATE / CUSTOM TASKS (Your Trained Model)
    if p_low.contains("devops") || p_low.contains("log") || p_low.contains("fix") {
        let ai_res = call_local_brain(&req.prompt).await;
        // Log "Billable" Task
        let _ = sqlx::query("INSERT INTO agent_tasks (from_agent, to_agent, task_description, status, resolution) VALUES ($1, $2, $3, 'solved', $4)")
            .bind("Client").bind("Custom_Local").bind(&req.prompt).bind(&ai_res)
            .execute(&pool).await;
        return Ok(warp::reply::json(&ChatResponse { response: format!("🛠️ (My-Trained-Brain): {}", ai_res) }));
    }

    // ROUTE B: COMPLEX REASONING (Gemini 3 Pro)
    let ai_res = call_google_gemini(&req.prompt).await;
    Ok(warp::reply::json(&ChatResponse { response: format!("💎 (Gemini-3-Pro): {}", ai_res) }))
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let db_url = env::var("DATABASE_URL").unwrap_or("postgres://athena:athena_pass@db:5432/athenadb".to_string());
    let pool = PgPool::connect(&db_url).await?;
    sqlx::query("CREATE TABLE IF NOT EXISTS agent_tasks (id SERIAL PRIMARY KEY, from_agent TEXT, to_agent TEXT, task_description TEXT, status TEXT DEFAULT 'pending', resolution TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)").execute(&pool).await?;
    
    let pool_filter = warp::any().map(move || pool.clone());
    let routes = warp::path("chat").and(warp::post()).and(warp::body::json()).and(pool_filter).and_then(handle_chat).with(warp::cors().allow_any_origin());

    println!("🚀 Athena Hybrid (Custom + Gemini 3 Pro) Active on 8080");
    warp::serve(routes).run(([0, 0, 0, 0], 8080)).await;
    Ok(())
}
