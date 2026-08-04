"""Checks each model folder's Cog build file.

RFD 0036 gives the rules. This script covers the ones a reader
forgets, and it leaves the rest to `cog build`.

A broken cog.yaml fails at build time, which is minutes away from the
edit that broke it. These checks run at commit time instead.
"""

import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("PyYAML is absent. Install it, or drop the cog-yaml-parses hook.", file=sys.stderr)
    raise SystemExit(1)

# RFD 0036 keeps these under x-weftspun so a human and RFD 0026 can
# read the same numbers cog.yaml declares.
REQUIRED_META = ["model_id", "license", "parameters"]


def check(path: Path) -> list[str]:
    problems = []
    try:
        doc = yaml.safe_load(path.read_text(encoding="utf-8"))
    except yaml.YAMLError as error:
        return [f"does not parse: {str(error).splitlines()[0]}"]

    if not isinstance(doc, dict):
        return ["is not a mapping"]

    if "predict" not in doc:
        problems.append("has no 'predict' key")

    meta = doc.get("x-weftspun")
    if not isinstance(meta, dict):
        problems.append("has no 'x-weftspun' block, which RFD 0036 requires")
        return problems

    for key in REQUIRED_META:
        if key not in meta:
            problems.append(f"x-weftspun has no '{key}'")

    # A composite names its domain. RFD 0037 gives that convention.
    if meta.get("composite") and "domain" not in meta:
        problems.append("is composite but names no 'domain'")

    # The domain path must resolve, or the Cog cannot plan.
    domain = meta.get("domain")
    if domain and not (path.parent / domain).resolve().exists():
        problems.append(f"names a domain that is absent: {domain}")

    return problems


def main(argv: list[str]) -> int:
    paths = [Path(a) for a in argv] or sorted(Path("decisions").glob("*/cog.yaml"))
    failed = 0

    for path in paths:
        problems = check(path)
        if problems:
            failed = 1
            for problem in problems:
                print(f"FAIL {path} {problem}", file=sys.stderr)

    if not failed:
        print(f"ok {len(paths)} cog.yaml file(s)")
    return failed


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
