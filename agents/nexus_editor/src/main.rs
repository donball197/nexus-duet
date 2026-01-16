use crossterm::{
    event::{self, DisableMouseCapture, EnableMouseCapture, Event, KeyCode, KeyEventKind},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::{backend::CrosstermBackend, Terminal};
use std::{error::Error, io, process::Command, time::{Duration, Instant}};

mod ui;

#[derive(PartialEq)]
pub enum InputMode { Normal, Editing }

pub struct App {
    pub content: String,
    pub mode: InputMode,
    pub current_file: Option<String>,
    pub terminal_buffer: Vec<String>,
    pub radar_active: bool,
    pub radar_timer: u64,
    pub cpu_load: u8,
    pub battery_level: String,
}

impl App {
    fn new() -> App {
        App {
            content: String::new(),
            mode: InputMode::Normal,
            current_file: Some("main.rs".to_string()),
            terminal_buffer: vec!["Nexus Cyber-Deck: Online".to_string()],
            radar_active: false,
            radar_timer: 0,
            cpu_load: 0,
            battery_level: "--%".to_string(),
        }
    }

    fn trigger_radar(&mut self, duration_ticks: u64) {
        self.radar_active = true;
        self.radar_timer = duration_ticks;
        self.terminal_buffer.push("📡 Radar Expansion: Reading Sensors...".to_string());
        
        // SENSOR ACTUATOR: Fetch real battery status via Termux API
        let output = Command::new("termux-battery-status").output();
        if let Ok(out) = output {
            let data = String::from_utf8_lossy(&out.stdout);
            if let Some(pos) = data.find("\"percentage\":") {
                let start = pos + 14;
                let rest = &data[start..];
                let end = rest.find(',').or_else(|| rest.find('}')).unwrap_or(3);
                self.battery_level = format!("{}%", &rest[..end].trim());
            }
        }
    }

    fn on_tick(&mut self) {
        if self.radar_active {
            self.cpu_load = if self.cpu_load < 90 { self.cpu_load + 5 } else { 10 };
            if self.radar_timer > 0 {
                self.radar_timer -= 1;
            } else {
                self.radar_active = false;
                self.terminal_buffer.push("Radar Retracted.".to_string());
            }
        }
    }
}

fn main() -> Result<(), Box<dyn Error>> {
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen, EnableMouseCapture)?;
    let mut terminal = Terminal::new(CrosstermBackend::new(stdout))?;
    let mut app = App::new();
    let tick_rate = Duration::from_millis(250);
    let mut last_tick = Instant::now();

    loop {
        terminal.draw(|f| ui::render(f, &mut app))?;
        let timeout = tick_rate.checked_sub(last_tick.elapsed()).unwrap_or_else(|| Duration::from_secs(0));
        if crossterm::event::poll(timeout)? {
            if let Event::Key(key) = event::read()? {
                if key.kind == KeyEventKind::Press {
                    match app.mode {
                        InputMode::Normal => match key.code {
                            KeyCode::Char('q') => break,
                            KeyCode::Char('e') => app.mode = InputMode::Editing,
                            KeyCode::Char('r') => app.trigger_radar(20), // 5 seconds
                            _ => {}
                        },
                        InputMode::Editing => match key.code {
                            KeyCode::Esc => app.mode = InputMode::Normal,
                            KeyCode::Char(c) => app.content.push(c),
                            KeyCode::Backspace => { app.content.pop(); }
                            KeyCode::Enter => app.content.push('\n'),
                            _ => {}
                        },
                    }
                }
            }
        }
        if last_tick.elapsed() >= tick_rate {
            app.on_tick();
            last_tick = Instant::now();
        }
    }
    disable_raw_mode()?;
    execute!(terminal.backend_mut(), LeaveAlternateScreen, DisableMouseCapture)?;
    Ok(())
}
