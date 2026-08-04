import Config

# A local single node CockroachDB cluster, started insecure:
#
#     cockroach start-single-node --insecure \
#       --store=.crdb/data --listen-addr=127.0.0.1:26257
#
# The insecure mode gives the `root` user with no password. Do not
# use that setting on a shared host.
config :weftspun_studio, WeftspunStudio.Repo,
  username: System.get_env("WEFTSPUN_DB_USER", "root"),
  password: System.get_env("WEFTSPUN_DB_PASSWORD", ""),
  hostname: System.get_env("WEFTSPUN_DB_HOST", "127.0.0.1"),
  port: String.to_integer(System.get_env("WEFTSPUN_DB_PORT", "26257")),
  database: System.get_env("WEFTSPUN_DB_NAME", "weftspun_studio_dev"),
  pool_size: 10,
  # CockroachDB has no PostgreSQL advisory lock, so the migrator
  # cannot take one. RFD 0020 records the constraint.
  migration_lock: false
