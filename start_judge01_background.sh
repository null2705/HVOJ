#!/usr/bin/env bash
set -u
cd "$HOME/hvoj" || exit 1
mkdir -p logs

CONFIG="$PWD/judge01.yml"
PY="$PWD/.venv/bin/python"

if [ ! -f "$CONFIG" ]; then
    echo "Khong tim thay $CONFIG"
    exit 1
fi

echo "=== Cau hinh judge01 ==="
sed -n '1,180p' "$CONFIG"

echo
echo "=== Tim chuong trinh judge ==="

# Tìm executable hoặc module trong môi trường ảo
JUDGE=""
for cmd in dmoj dmoj-judge judge; do
    if [ -x "$PWD/.venv/bin/$cmd" ]; then
        JUDGE="$PWD/.venv/bin/$cmd"
        break
    fi
done

if [ -n "$JUDGE" ]; then
    echo "Tim thay: $JUDGE"
    nohup "$JUDGE" -c "$CONFIG" >> logs/judge01.log 2>&1 </dev/null &
    PID=$!
    echo "$PID" > logs/judge01.pid
    sleep 3
    if kill -0 "$PID" 2>/dev/null; then
        echo "Judge01 dang chay nen, PID=$PID"
        echo "Log: logs/judge01.log"
    else
        echo "Judge da thoat. Xem log:"
        tail -n 80 logs/judge01.log
    fi
else
    echo "Khong tim thay executable dmoj/dmoj-judge/judge."
    echo "Tim package va entry point:"
    "$PY" -m pip show dmoj-judge 2>/dev/null || true
    find "$PWD/.venv/bin" -maxdepth 1 -type f \
        \( -iname '*judge*' -o -iname '*dmoj*' \) -print
    echo
    echo "Chua khoi dong judge de tranh chay sai lenh."
    echo "Hay xem cau hinh va log bridge:"
    tail -n 50 logs/bridge.log 2>/dev/null || true
    exit 1
fi
