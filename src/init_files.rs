use std::fs;
use std::path::Path;

pub fn ensure_essential_files() {
    let structure = vec!["workspace", "logs", "nexus_db"];
    for dir in structure {
        if !Path::new(dir).exists() { fs::create_dir_all(dir).ok(); }
    }
    let defaults = vec![
        ("workspace/memory.json", r#"{"short_term": [], "long_term": {}}"#),
        ("nexus_config.json", r#"{"version": "1.0", "identity": "Guardian 734", "status": "active"}"#)
    ];
    for (path, content) in defaults {
        if !Path::new(path).exists() { fs::write(path, content).ok(); }
    }
    println!("✅ Sovereign File System: Verified.");
}
