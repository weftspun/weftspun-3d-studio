# Database tests need a local CockroachDB cluster. Start it with:
#     cockroach start-single-node --insecure --store=.crdb/data \
#       --listen-addr=127.0.0.1:26257
Ecto.Adapters.SQL.Sandbox.mode(CharacterTaxonomy.Repo, :manual)

ExUnit.start()
