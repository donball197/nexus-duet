
pub async fn init_dead_letter(pool: &sqlx::SqlitePool) {
    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS dead_tasks (
            id TEXT PRIMARY KEY,
            payload TEXT NOT NULL,
            error TEXT NOT NULL
        );
        "#
    )
    .execute(pool)
    .await
    .unwrap();
}
