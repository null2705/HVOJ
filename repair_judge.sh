#!/usr/bin/env bash
set -u

ROOT=/home/huy/hvoj
CFG="$ROOT/judge01.yml"
VENV="$ROOT/.venv"
LOG="$ROOT/logs/repair_judge.log"
STAMP=$(date +%Y%m%d-%H%M%S)

mkdir -p "$ROOT/logs"
exec > >(tee -a "$LOG") 2>&1

echo
echo "========== HVOJ REPAIR $STAMP =========="

# 1. Kiểm tra cấu hình và môi trường
if [ ! -x "$VENV/bin/dmoj" ]; then
    echo "LOI: Khong tim thay $VENV/bin/dmoj"
    exit 1
fi

if [ ! -f "$CFG" ]; then
    echo "LOI: Khong tim thay $CFG"
    exit 1
fi

# 2. Sao lưu cấu hình
cp -a "$CFG" "$CFG.backup-$STAMP"

# 3. Kiểm tra YAML
if ! "$VENV/bin/python" - "$CFG" <<'PY'
import sys
try:
    import yaml
    with open(sys.argv[1], encoding="utf-8") as f:
        d = yaml.safe_load(f)
    assert isinstance(d, dict)
    assert d.get("id") == "judge01"
    assert d.get("problem_storage_globs")
    print("YAML OK")
except Exception as e:
    print("YAML ERROR:", repr(e))
    sys.exit(1)
PY
then
    echo "Dung: cau hinh khong hop le. Ban sao: $CFG.backup-$STAMP"
    exit 1
fi

# 4. Kiểm tra dữ liệu bài tập, không xóa hay sửa dữ liệu
echo "--- Problem directories ---"
for d in "$ROOT/problem_data" /home/huy/vnoj-site/problem_data; do
    if [ -d "$d" ]; then
        echo "Directory: $d"
        find "$d" -mindepth 1 -maxdepth 1 -type d -printf '%f\n'
    fi
done

echo "--- hvhieu init.yml ---"
for f in \
    "$ROOT/problem_data/hvhieu/init.yml" \
    /home/huy/vnoj-site/problem_data/hvhieu/init.yml; do
    if [ -f "$f" ]; then
        echo "FOUND: $f"
        sed -n '1,100p' "$f"
    fi
done

# 5. Kiểm tra chương trình thực thi cần thiết
echo "--- Runtime checks ---"
for f in /usr/local/bin/scratch-run /usr/bin/g++ /usr/bin/gcc; do
    if [ -x "$f" ]; then
        echo "OK: $f"
    else
        echo "MISSING: $f"
    fi
done

# 6. Phát hiện các Judge trùng thuộc đúng thư mục dự án
echo "--- Judge processes ---"
pgrep -af 'DMOJ Judge judge01' || true

echo
echo "Da hoan tat kiem tra."
echo "Log: $LOG"
echo "Neu co nhieu Judge, hay dung cac tien trinh cu bang lenh khoi dong chuan cua ban."
echo "Khong tu dong kill Judge de tranh cat ngang bai dang cham."
