use sysinfo::{System, RefreshKind, CpuRefreshKind, MemoryRefreshKind};
use std::{thread, time};

fn main() {
    println!("🚀 INITIALIZING SENSORS...");
    
    // Setup the sensor array
    let mut sys = System::new_with_specifics(
        RefreshKind::new()
            .with_cpu(CpuRefreshKind::everything())
            .with_memory(MemoryRefreshKind::everything())
    );

    loop {
        // Refresh sensor data
        sys.refresh_all();

        // Clear the screen (Linux/Mac code)
        print!("\x1b[2J\x1b[1;1H");

        println!("==========================================");
        println!("      NEXUS SYSTEM MONITOR v1.0");
        println!("==========================================");
        
        // Memory Math (Convert Bytes to Megabytes)
        let total_ram = sys.total_memory() / 1024 / 1024;
        let used_ram = sys.used_memory() / 1024 / 1024;
        
        println!("RAM Usage:   {} MB / {} MB", used_ram, total_ram);
        println!("CPU Cores:   {}", sys.cpus().len());
        println!("------------------------------------------");

        // Check each CPU Core
        for (i, cpu) in sys.cpus().iter().enumerate() {
            println!("Core {:<2}:      {:.1}%", i, cpu.cpu_usage());
        }
        
        println!("==========================================");
        println!("Press Ctrl+C to Exit");

        // Update every 1 second
        thread::sleep(time::Duration::from_secs(1));
    }
}
