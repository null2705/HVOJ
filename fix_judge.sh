#!/usr/bin/env bash
set -u

ROOT=/home/huy/hvoj
CFG="$ROOT/judge01.yml"
PY="$ROOT/.venv/bin/python"
JUDGE="$ROOT/.venv/bin/dmoj"
LOG="$ROOT/logs/fix_judge.log"
DATA=/home/huy/vnoj-site/problem_data

mkdir -p "$ROOT/logs" || exit 1

echo "===== HVOJ FIX $(date) ====="

# Kiem tra cac file bat buoc
for f in "$CFG" "$PY" "$JUDGE"; do
    if [ ! -e "$f" ]; then
        echo "LOI: Khong tim thay $f"
        exit 1
    fi
done

if [ ! -x "$PY" ] || [ ! -x "$JUDGE" ]; then
    echo "LOI: Python hoac DMOJ khong co quyen thuc thi"
    exit 1
fi

# Kiem tra YAML truoc khi sua bat ky thu gi
if ! "$PY" - "$CFG" <<'PY'
import sys
try:
    import yaml
    with open(sys.argv[1], encoding="utf-8") as f:
        c = yaml.safe_load(f)
    assert isinstance(c, dict), "YAML khong phai object"
    assert c.get("id") == "judge01", "ID Judge khong dung"
    assert c.get("problem_storage_globs"), "Thieu problem_storage_globs"
    assert c.get("problem_storage_root"), "Thieu problem_storage_root"
    print("Cau hinh YAML hop le")
except Exception as e:
    print("LOI CAU HINH:", e)
    sys.exit(1)
PY
then
    echo "Dung de tranh lam hong cau hinh."
    exit 1
fi

# Sao luu cau hinh
STAMP=$(date +%Y%m%d-%H%M%S)
cp -a "$CFG" "$CFG.backup-$STAMP" || exit 1
echo "Da sao luu cau hinh: $CFG.backup-$STAMP"

# Kiem tra du lieu bai tap
echo "===== DU LIEU HVHIEU ====="
if [ -f "$DATA/hvhieu/init.yml" ]; then
    echo "Tim thay $DATA/hvhieu/init.yml"
else
    echo "CANH BAO: Khong tim thay init.yml cua hvhieu tai $DATA"
fi

# Kiem tra runtime
echo "===== RUNTIME ====="
for f in /usr/bin/g++ /usr/bin/gcc /usr/local/bin/scratch-run; do
    if [ -x "$f" ]; then
        echo "OK $f"
    else
        echo "THIEU $f"
    fi
done

# Ghi lai trang thai Judge va log
{
    echo "===== CAC JUDGE ====="
    pgrep -af '^DMOJ Judge judge01 on 127\.0\.0\.1:9999$' || true
    echo "===== CONG 9999 ====="
    ss -ltnp 2>/dev/null | grep ':9999' || true
    echo "===== LOG GAN DAY ====="
    tail -n 40 "$ROOT/logs/judge01.log" 2>/dev/null || true
} >> "$LOG" 2>&1

echo "===== KET QUA ====="
tail -n 50 "$LOG"
echo "Da kiem tra xong. Log: $LOG"
echo "Script khong tu kill Judge va khong xoa du lieu bai."
