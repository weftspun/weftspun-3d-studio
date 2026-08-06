# RFD 0076 split this from weftspun_studio/.formatter.exs. The
# RECTGTN HTN domains and problems that live beside their RFDs (RFD
# 0037 records why those are Elixir DSL, not JSON) format from here,
# at the repo root, since they belong to no single app. The studio's
# own {config,lib,test} format from weftspun_studio/.formatter.exs
# instead, now that RFD 0076 moved it into its own subdirectory.
[
  inputs: ["decisions/**/*.{ex,exs}"],
  line_length: 98
]
