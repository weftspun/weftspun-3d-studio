# Two trees share this file since RFD 0060's swap put weftspun_studio
# at the repo root: the RECTGTN HTN domains and problems that live
# beside their RFDs (RFD 0037 records why those are Elixir DSL, not
# JSON), and the studio application itself.
[
  inputs: [
    "decisions/**/*.{ex,exs}",
    "{mix,.formatter}.exs",
    "{config,lib,test}/**/*.{ex,exs}"
  ],
  line_length: 98
]
