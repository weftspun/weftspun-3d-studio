import Config

config :character_taxonomy, ecto_repos: [CharacterTaxonomy.Repo]

import_config "#{config_env()}.exs"
