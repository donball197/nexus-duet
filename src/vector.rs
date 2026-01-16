pub struct VectorEngine;
impl VectorEngine {
    pub fn new() -> Self { Self }
    pub async fn encode(&self, _t: &str) -> Vec<f32> { vec![0.0; 384] }
}
