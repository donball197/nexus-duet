use serde::{Serialize, Deserialize};
use std::net::UdpSocket;

#[derive(Serialize, Deserialize, Debug)]
pub struct Pulse {
    pub node_id: String,
    pub cpu: f32,
    pub ram: f32,
}

pub struct PulseAgent {
    pub socket: UdpSocket,
}

impl PulseAgent {
    pub fn new() -> Self {
        Self { socket: UdpSocket::bind("0.0.0.0:0").expect("Bind failed") }
    }

    pub fn send(&self, target: &str, id: &str) {
        let p = Pulse { node_id: id.to_string(), cpu: 0.0, ram: 0.0 };
        if let Ok(data) = serde_json::to_string(&p) {
            let _ = self.socket.send_to(data.as_bytes(), target);
        }
    }
}
