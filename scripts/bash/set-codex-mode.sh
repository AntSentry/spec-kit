#!/usr/bin/env bash
set -euo pipefail

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
MODE=${1:-}
if [[ -z "$MODE" ]]; then
  echo "Usage: $0 <mode>" >&2
  echo "Modes: fast, thorough, safety (freeform accepted; stored as-is)" >&2
  exit 1
fi
CFG="$ROOT/.specify/codex.json"
mkdir -p "$(dirname "$CFG")"
if [[ -f "$CFG" ]]; then
  python3 - "$CFG" "$MODE" <<'PY'
import json,sys
cfg=sys.argv[1]; mode=sys.argv[2]
try:
  d=json.load(open(cfg))
except Exception:
  d={}
d['mode']=mode
json.dump(d, open(cfg,'w'), indent=2)
print('Set Codex mode:', mode)
PY
else
  printf '{\n  "mode": "%s"\n}\n' "$MODE" > "$CFG"
  echo "Set Codex mode: $MODE"
fi

