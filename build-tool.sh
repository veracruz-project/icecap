#!/bin/sh

set -eu

here="$(dirname "$0")"

PYTHONPATH="$here/build:${PYTHONPATH:-}" exec python3 -m build_tool.cli "$@"
