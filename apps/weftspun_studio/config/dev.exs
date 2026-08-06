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

# RFD 0076: usd_viewer_app runs as its own app now (its own `npm
# run start`, or `docker run` from usd_viewer_app/Dockerfile), on
# this default port. WeftspunStudio.Adapters.HttpGallery reaches it
# here in dev.
config :weftspun_studio, :gallery_url, System.get_env("GALLERY_URL", "http://localhost:8090")
