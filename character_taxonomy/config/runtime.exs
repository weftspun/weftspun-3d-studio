import Config

# A release carries no config file for its database settings, so a
# release reads them from the environment at boot. This service's
# CockroachDB is its own, not weftspun_studio's, per RFD 0065's
# "separate service" framing.
if config_env() == :prod do
  config :character_taxonomy, CharacterTaxonomy.Repo,
    username: System.get_env("TAXONOMY_DB_USER", "root"),
    password: System.get_env("TAXONOMY_DB_PASSWORD", ""),
    hostname: System.get_env("TAXONOMY_DB_HOST", "127.0.0.1"),
    port: String.to_integer(System.get_env("TAXONOMY_DB_PORT", "26257")),
    database: System.get_env("TAXONOMY_DB_NAME", "character_taxonomy"),
    pool_size: String.to_integer(System.get_env("TAXONOMY_DB_POOL", "5")),
    migration_lock: false
end
