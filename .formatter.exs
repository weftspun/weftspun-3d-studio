# Formats the RECTGTN HTN domains and problems that live beside their
# RFDs. RFD 0037 records why those files are Elixir DSL and not JSON.
#
# extension/popcorn is a real Mix project with its own .formatter.exs,
# and `mix format` uses the nearest one. This file therefore names the
# decisions tree only.
[
  inputs: ["decisions/**/*.{ex,exs}", ".formatter.exs"],
  line_length: 98
]
