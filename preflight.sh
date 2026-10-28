#!/usr/bin/env bash
set -eu
cd /home/huy/hvoj

echo "=== 1. Kiem tra cau hinh ==="
.venv/bin/python - <<'PY'
from pathlib import Path
import yaml

cfg = Path("judge01.yml")
data = yaml.safe_load(cfg.read_text())
assert isinstance(data, dict), "judge01.yml khong hop le"

globs = data.get("problem_storage_globs") or []
roots = data.get("problem_storage_root") or []
assert globs or roots, "Chua cau hinh thu muc de"

print("Cau hinh YAML OK")
PY

echo "=== 2. Kiem tra de ==="
.venv/bin/python check_problems.py

echo "=== 3. Kiem tra cac dich vu ==="
curl -fsS --max-time 3 http://127.0.0.1:8000/ >/dev/null \
  && echo "Web OK" || echo "CAN KIEM TRA WEB"
timeout 2 bash -c '</dev/tcp/127.0.0.1/9999' \
  && echo "Bridge OK" || echo "CAN KIEM TRA BRIDGE"

echo "=== Hoan tat kiem tra ==="
