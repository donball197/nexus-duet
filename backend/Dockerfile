# We switch from '1.83-slim' to 'latest' to get Edition 2024 support
FROM rust:latest as builder

# Install dependencies
RUN apt-get update && apt-get install -y pkg-config libssl-dev && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .

# Build the release binary
RUN cargo build --release

# Create the final small image
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y libssl-dev ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/athenafusionx-backend /athena
CMD ["/athena"]
