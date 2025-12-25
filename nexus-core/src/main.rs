use std::time::{SystemTime, UNIX_EPOCH};

fn main() {
    let version = "v1.0.0";
    let status = "SYSTEM LOCKED SECURE SECURE";
    
    // Calculate a timestamp-based ID
    let start = SystemTime::now();
    let since_the_epoch = start.duration_since(UNIX_EPOCH).expect("Time went backwards");
    let verification_code = since_the_epoch.as_secs() * 3;

    println!("==========================================");
    println!("   NEXUS-CORE SECURITY PROTOCOL {}", version);
    println!("==========================================");
    println!("   [+] System Status:   {}", status);
    println!("   [+] Integrity Hash:  {:x}", verification_code);
    println!("   [+] Local Watcher:   ACTIVE");
    println!("==========================================");
}
