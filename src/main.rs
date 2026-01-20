mod billing;
mod pulse_agent;
use std::env;

#[tokio::main]
async fn main() -> std::io::Result<()> {
    let hostname = env::var("HOSTNAME").unwrap_or_else(|_| "unknown".to_string());
    
    if hostname.contains("penguin") {
        println!("🏛️ ORACLE HUB ACTIVE: LISTENING ON PORT 7340");
        let socket = tokio::net::UdpSocket::bind("0.0.0.0:7340").await?;
        let mut buf = [0; 1024];
        loop {
            let (len, addr) = socket.recv_from(&mut buf).await?;
            println!("📥 Pulse received from: {}", addr);
            billing::log_billable_event("HEARTBEAT_RECVD", "MOTOROLA_SENTINEL");
        }
    } else {
        println!("📡 SENTINEL ACTIVE: PULSING TO ORACLE...");
        let agent = pulse_agent::PulseAgent::new();
        loop {
            // Replace with your actual Duet IP from 'hostname -I'
            agent.send("100.115.92.2:7340", "FIELD_01");
            tokio::time::sleep(std::time::Duration::from_secs(5)).await;
        }
    }
}
