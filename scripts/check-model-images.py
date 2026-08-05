"""Checks each model folder's Docker image.

RFD 0036 gives the rules. This script covers the ones a reader
forgets, and it leaves the rest to `docker build`.

A broken server.py fails when a rented GPU starts it, which is money
away from the edit that broke it. These checks run at commit time.
"""

import ast
import json
import sys
from pathlib import Path

# RFD 0036. vast.ai runs no health probe of its own, thus a caller
# polls /health until the instance is ready.
REQUIRED_ROUTES = ["/health", "/predict"]


def check_server(path: Path) -> list[str]:
    problems = []
    source = path.read_text(encoding="utf-8")

    try:
        ast.parse(source)
    except SyntaxError as error:
        return [f"does not parse: line {error.lineno}: {error.msg}"]

    for route in REQUIRED_ROUTES:
        if f'"{route}"' not in source:
            problems.append(f"serves no {route}, which RFD 0036 requires")

    # The contract stage runs with no GPU and no weights. Without this
    # switch the image cannot be tested anywhere but a rented card.
    if "WEFTSPUN_STUB" not in source:
        problems.append("reads no WEFTSPUN_STUB, thus the contract cannot be tested")

    return problems


def check_dockerfile(path: Path) -> list[str]:
    problems = []
    source = path.read_text(encoding="utf-8")

    if "AS contract" not in source:
        problems.append("has no contract stage, which RFD 0036 requires")

    if "AS worker" not in source:
        problems.append("has no worker stage")

    # Cog is gone. RFD 0036 records why.
    if "cog.yaml" in source or "runpod" in source.lower():
        problems.append("names Cog or RunPod, and RFD 0036 selects plain Docker on vast.ai")

    return problems


def check_input(path: Path) -> list[str]:
    try:
        body = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        return [f"does not parse: {error}"]

    # An HTTP body is the request. A RunPod-shaped {"input": ...}
    # wrapper makes every field missing, and the server answers 422.
    if isinstance(body, dict) and set(body) == {"input"}:
        return ['wraps the body in "input", which no HTTP route reads']

    return []


CHECKS = {
    "server.py": check_server,
    "Dockerfile": check_dockerfile,
    "test_input.json": check_input,
}


def main(argv: list[str]) -> int:
    paths = [Path(a) for a in argv]

    if not paths:
        for name in CHECKS:
            paths += sorted(Path("decisions").glob(f"*/{name}"))

    failed = 0
    for path in paths:
        check = CHECKS.get(path.name)
        if not check:
            continue

        for problem in check(path):
            failed = 1
            print(f"FAIL {path} {problem}", file=sys.stderr)

    if not failed:
        print(f"ok {len(paths)} model image file(s)")
    return failed


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
