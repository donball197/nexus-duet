use std::{thread, time};
use rand::Rng;

fn main() {
    let mut rng = rand::thread_rng();
    let raw_chars = "ﾊﾐﾋｰｳｼﾅﾓﾆｻﾜﾂｵﾘｱﾎﾃﾏｹﾒｴｶｷﾑﾕﾗｾﾈｽﾀﾇﾍ1234567890";
    // FIX: Convert to a list of characters first!
    let chars: Vec<char> = raw_chars.chars().collect();
    
    let version = "v0.3.2 (MATRIX RELOADED)";

    print!("\x1b[2J\x1b[1;1H"); // Clear Screen
    println!("🚀 INITIALIZING NEXUS VISUALS: {}", version);
    thread::sleep(time::Duration::from_secs(2));

    // Infinite Rain Loop
    loop {
        let mut line = String::new();
        for _ in 0..60 {
            if rng.gen_bool(0.3) {
                 // Safe access using the character list
                 let idx = rng.gen_range(0..chars.len());
                 let c = chars[idx];
                 line.push(c);
                 line.push(' ');
            } else {
                 line.push_str("  ");
            }
        }
        // Print green text
        println!("\x1b[32m{}\x1b[0m", line);
        
        // Speed of rain
        thread::sleep(time::Duration::from_millis(50));
    }
}
