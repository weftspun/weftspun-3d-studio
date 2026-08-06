# RFD 0063: STE enforcement moves to the plugin

**State:** discussion
**Scope:** `decisions/`, `scripts/ci.sh`, `.pre-commit-config.yaml`

## Problem

RFD 0000 named `scripts/ste-lint-decisions.py` as this repository's
STE linter. It scored each RFD's prose at violations per 100 words.
It ran in CI, through `npm run lint:ste`. It ran again in
`.pre-commit-config.yaml`'s `ste-lint` hook. Three places ran the
same check on the same files.

`fire/claude-ste-plugin` is a Claude Code plugin. It checks at a
better point in the process. It lints the reply before the reply
reaches a file, and it asks for a rewrite. The old script
caught a violation only after a commit already held it. Two
enforcement points for one rule is the DRY policy's own complaint,
turned on this repository's own tooling.

## Decision

Delete `scripts/ste-lint-decisions.py`. Delete its `npm run lint:ste`
entry in `thirdparty/3d_studio/package.json`. Delete its step in
`scripts/ci.sh`, and its hook in `.pre-commit-config.yaml`. STE
enforcement now runs once, in the plugin's `Stop` hook, at write
time.

See `DETAILS.md` for what moved to the plugin, including three new
checks this repository contributed upstream. It also names what the
deleted script's aggregate score this repository does not gain back.

## Related

RFD 0000 named the deleted script. RFD 0059 wired `npm run lint:ste`
into `scripts/ci.sh`. This RFD removes that step, and nothing
replaces it. `fire/claude-ste-plugin#1` is the PR that carries this
repository's contribution upstream.
