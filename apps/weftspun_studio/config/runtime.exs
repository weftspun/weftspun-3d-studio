import Config

# A Burrito binary carries no config file, so the release reads the
# database settings from the environment when it boots.
if config_env() == :prod do
  config :weftspun_studio, WeftspunStudio.Repo,
    username: System.get_env("WEFTSPUN_DB_USER", "root"),
    password: System.get_env("WEFTSPUN_DB_PASSWORD", ""),
    hostname: System.get_env("WEFTSPUN_DB_HOST", "127.0.0.1"),
    port: String.to_integer(System.get_env("WEFTSPUN_DB_PORT", "26257")),
    database: System.get_env("WEFTSPUN_DB_NAME", "weftspun_studio"),
    pool_size: String.to_integer(System.get_env("WEFTSPUN_DB_POOL", "10")),
    migration_lock: false
end

# RFD 0076: usd_viewer_app runs as its own app now, reached over
# HTTP. Not gated on config_env() == :prod: a Burrito binary reads
# this at actual runtime the same way it reads WEFTSPUN_DB_HOST.
config :weftspun_studio, :gallery_url, System.get_env("GALLERY_URL", "http://localhost:8090")
