import Config

# The same local single-node CockroachDB cluster weftspun_studio's
# config/dev.exs starts, on a separate database.
config :character_taxonomy, CharacterTaxonomy.Repo,
  username: System.get_env("WEFTSPUN_DB_USER", "root"),
  password: System.get_env("WEFTSPUN_DB_PASSWORD", ""),
  hostname: System.get_env("WEFTSPUN_DB_HOST", "127.0.0.1"),
  port: String.to_integer(System.get_env("WEFTSPUN_DB_PORT", "26257")),
  database: System.get_env("CHARACTER_TAXONOMY_DB_NAME", "character_taxonomy_dev"),
  pool_size: 10,
  migration_lock: false
