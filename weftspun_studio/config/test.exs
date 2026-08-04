import Config

# The suite runs against the same local cluster on a separate
# database. Every test case takes a sandbox connection, so a test
# leaves no row behind.
config :weftspun_studio, WeftspunStudio.Repo,
  username: System.get_env("WEFTSPUN_DB_USER", "root"),
  password: System.get_env("WEFTSPUN_DB_PASSWORD", ""),
  hostname: System.get_env("WEFTSPUN_DB_HOST", "127.0.0.1"),
  port: String.to_integer(System.get_env("WEFTSPUN_DB_PORT", "26257")),
  database: System.get_env("WEFTSPUN_DB_NAME", "weftspun_studio_test"),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  migration_lock: false

config :logger, level: :warning
