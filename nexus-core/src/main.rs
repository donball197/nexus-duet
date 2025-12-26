use actix_web::{get, web, App, HttpServer, HttpResponse, Responder};
use sysinfo::{System, RefreshKind, CpuRefreshKind, MemoryRefreshKind};
use std::{thread, time, fs::OpenOptions, io::Write, sync::Mutex};
use chrono::Local;

// Shared State (The "Brain" that both threads can access)
struct AppState {
    sys_data: Mutex<String>,
}

// THE WEBPAGE FUNCTION
#[get("/")]
async fn index(data: web::Data<AppState>) -> impl Responder {
    let status = data.sys_data.lock().unwrap();
    
    // This HTML String builds your dashboard
    let html = format!(r#"
        <html>
        <head>
            <meta charset="utf-8">  <title>NEXUS DAEMON</title>
            <meta http-equiv="refresh" content="1"> <style>
                body {{ background-color: #0d1117; color: #00ff41; font-family: monospace; display: flex; justify-content: center; align-items: center; height: 100vh; }}
                .box {{ border: 2px solid #00ff41; padding: 40px; border-radius: 10px; box-shadow: 0 0 20px #00ff41; }}
                h1 {{ margin-top: 0; }}
            </style>
        </head>
        <body>
            <div class="box">
                <h1>🚀 NEXUS STATUS: ONLINE</h1>
                <pre>{}</pre>
            </div>
        </body>
        </html>
    "#, *status);
    
    HttpResponse::Ok().content_type("text/html").body(html)
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    println!("🚀 NEXUS WEB SERVER STARTING...");
    
    // Create Shared Memory
    let shared_state = web::Data::new(AppState {
        sys_data: Mutex::new("Initializing...".to_string()),
    });

    let state_clone = shared_state.clone();

    // THREAD 1: The Recorder (Background)
    thread::spawn(move || {
        let mut sys = System::new_with_specifics(
            RefreshKind::new().with_cpu(CpuRefreshKind::everything()).with_memory(MemoryRefreshKind::everything())
        );
        let mut file = OpenOptions::new().create(true).append(true).open("nexus_stats.csv").expect("No CSV access");

        loop {
            sys.refresh_all();
            let time = Local::now().format("%H:%M:%S");
            let ram = sys.used_memory() / 1024 / 1024;
            let total = sys.total_memory() / 1024 / 1024;
            let cpu = sys.global_cpu_info().cpu_usage();

            // Write to CSV
            writeln!(file, "{},{},{},{:.1}", time, ram, total, cpu).unwrap();

            // Update Web Server
            let display_text = format!(
                "Time: {}\nRAM:  {} / {} MB\nCPU:  {:.1}%\n\n[RECORDER ACTIVE]", 
                time, ram, total, cpu
            );
            *state_clone.sys_data.lock().unwrap() = display_text;

            thread::sleep(time::Duration::from_secs(1));
        }
    });

    // THREAD 2: The Web Server (Main)
    println!("🌍 Server running at: http://localhost:8080");
    HttpServer::new(move || {
        App::new()
            .app_data(shared_state.clone())
            .service(index)
    })
    .bind(("0.0.0.0", 8080))?
    .run()
    .await
}