#!/usr/bin/env bash
# Fetch the RFD 0064 (weftspun/request-for-discussion) training
# dataset: alfredplpl/anime-with-caption-cc0. CC0, 15,000 rows,
# image + phi3_caption + phi3_caption_ja + prompt, about 20.9 GB.
# Clones with git-xet (git-lfs as its fallback), never committed:
# .gitignore excludes the target directory.
#
# Usage: bash scripts/fetch-anime-caption-dataset.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="$ROOT/datasets/anime-caption-cc0"

if [[ -d "$TARGET/.git" ]]; then
  echo "already cloned at $TARGET, pulling instead"
  git -C "$TARGET" pull
  exit 0
fi

mkdir -p "$(dirname "$TARGET")"
git clone https://huggingface.co/datasets/alfredplpl/anime-with-caption-cc0 "$TARGET"

echo "cloned to $TARGET"
