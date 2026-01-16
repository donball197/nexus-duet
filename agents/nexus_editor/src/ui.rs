use ratatui::{
    layout::{Constraint, Direction, Layout},
    style::{Color, Style},
    widgets::{Block, Borders, Paragraph, BorderType},
    Frame,
};
use crate::{App, InputMode};

pub fn render(f: &mut Frame, app: &mut App) {
    let size = f.area();
    
    // DYNAMIC FOLDING
    let radar_height = if app.radar_active { Constraint::Length(3) } else { Constraint::Length(1) };
    
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Min(0),      // Editor
            radar_height,            // Radar (Peek)
            Constraint::Length(3),   // Console
        ])
        .split(size);

    // 1. Editor
    let editor_block = Block::default()
        .title(" 🛰️ NEXUS EYES ")
        .borders(Borders::BOTTOM)
        .border_style(Style::default().fg(if app.mode == InputMode::Editing { Color::Magenta } else { Color::DarkGray }));
    f.render_widget(Paragraph::new(app.content.as_str()).block(editor_block), chunks[0]);

    // 2. Radar
    let radar_style = if app.radar_active { Style::default().fg(Color::Cyan) } else { Style::default().fg(Color::DarkGray) };
    let radar_text = if app.radar_active {
        format!(" 📡 RADAR: [ACTIVE] | CPU: {}% | BAT: {} ", app.cpu_load, app.battery_level)
    } else {
        format!(" 📡 RADAR: [IDLE] | BAT: {} ", app.battery_level)
    };
    
    let radar_block = Block::default()
        .borders(if app.radar_active { Borders::ALL } else { Borders::TOP })
        .border_type(BorderType::Rounded)
        .border_style(radar_style);
    f.render_widget(Paragraph::new(radar_text).block(radar_block), chunks[1]);

    // 3. Console
    let last_msg = app.terminal_buffer.last().cloned().unwrap_or_default();
    let console = Paragraph::new(format!(" > {}", last_msg))
        .style(Style::default().fg(Color::Cyan))
        .block(Block::default().borders(Borders::TOP).border_style(Style::default().fg(Color::DarkGray)));
    f.render_widget(console, chunks[2]);
}
