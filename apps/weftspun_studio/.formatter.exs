# RFD 0076 moved this app into its own subdirectory, and split the
# repo root's shared .formatter.exs in two: the RECTGTN HTN domains
# beside their RFDs format from the repo root's own .formatter.exs
# now, and this app's own {config,lib,test} format from here.
[
  inputs: [
    "{mix,.formatter}.exs",
    "{config,lib,test}/**/*.{ex,exs}"
  ],
  line_length: 98
]
