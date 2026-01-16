use std::env;
use std::fs;

pub fn load_api_key() {
    // Check current env first
    if let Ok(key) = env::var("GEMINI_API_KEY") {
        if !key.is_empty() {
            println!("✅ GEMINI_API_KEY detected in active environment.");
            return;
        }
    }

    let bashrc_path = format!("{}/.bashrc", env::var("HOME").unwrap_or_default());
    println!("🔍 Searching for key in: {}", bashrc_path);

    if let Ok(content) = fs::read_to_string(&bashrc_path) {
        for line in content.lines() {
            let line = line.trim();
            if line.starts_with("export GEMINI_API_KEY=") {
                if let Some(eq) = line.find('=') {
                    let val = line[eq+1..].trim().trim_matches('"').trim_matches('\'');
                    env::set_var("GEMINI_API_KEY", val);
                    println!("✅ GEMINI_API_KEY loaded and exported.");
                    return;
                }
            }
        }
    }
    eprintln!("⚠️ GEMINI_API_KEY not found in .bashrc!");
}
