#!/bin/bash
set -e
PROJ_NAME=rust
mkdir -p "$PROJ_NAME"
cd "$PROJ_NAME"
cat << 'EOF_NEXUS' > "Cargo.toml"
[package]
name = "hello_world"
version = "0.1.0"
edition = "2021" # Using the latest stable edition

# See more keys and their definitions at https://doc.rust-lang.org/cargo/reference/manifest.html

[dependencies]

EOF_NEXUS
mkdir -p "src"
cat << 'EOF_NEXUS' > "src/main.rs"
fn main() {
    // The classic "Hello, World!" message.
    // println! is a macro that prints text to the console.
    println!("Hello, world!");
}

EOF_NEXUS
echo '✅ Project created in '$PROJ_NAME