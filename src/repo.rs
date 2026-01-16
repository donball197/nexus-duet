use std::sync::Arc; use crate::AppState; pub fn router(_s: Arc<AppState>) -> axum::Router { axum::Router::new().route("/", axum::routing::get(|| async { "STUB" })) }
