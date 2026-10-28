#!/usr/bin/env bash
set -u
cd "$HOME/hvoj" || exit 1
mkdir -p logs
REPORT="$HOME/hvoj/logs/full_audit_$(date +%Y%m%d_%H%M%S).txt"
exec > >(tee "$REPORT") 2>&1

section() { printf '\n\n========== %s ==========\n' "$1"; }
check_port() {
    if timeout 2 bash -c "echo >/dev/tcp/127.0.0.1/$1" 2>/dev/null; then
        echo "[OK] Cổng $1 kết nối được"
    else
        echo "[LOI] Cổng $1 không kết nối được"
    fi
}

section "1. THONG TIN HE THONG"
date
pwd
df -h "$HOME" /
free -h 2>/dev/null || true

section "2. DJANGO SYSTEM CHECK"
.venv/bin/python manage.py check || echo "[LOI] manage.py check"
.venv/bin/python manage.py check --deploy 2>&1 || true

section "3. MIGRATION"
.venv/bin/python manage.py showmigrations --plan 2>&1 | tail -n 50
.venv/bin/python manage.py makemigrations --check --dry-run 2>&1 || \
    echo "[CAN XEM] Có thể còn model chưa có migration; chưa tự tạo."

section "4. DATABASE"
.venv/bin/python manage.py shell -c '
from django.db import connection
with connection.cursor() as c:
    c.execute("SELECT 1")
    print("Database query:", c.fetchone())
' 2>&1 || echo "[LOI] Không truy vấn được database"

section "5. REDIS"
check_port 6379
if command -v redis-cli >/dev/null 2>&1; then
    redis-cli ping 2>&1 || true
fi

section "6. RABBITMQ / CELERY"
check_port 5672
if command -v rabbitmqctl >/dev/null 2>&1; then
    sudo service rabbitmq-server start 2>&1 || true
    sudo rabbitmqctl status 2>&1 | head -n 35 || true
else
    echo "[CAN XEM] Không tìm thấy rabbitmqctl trong PATH."
fi
grep -RInE 'CELERY_BROKER_URL|BROKER_URL|amqp://|redis://' \
    local_settings.py settings.py 2>/dev/null | head -n 80 || true

section "7. CAC CONG DICH VU"
for port in 8000 9999 3306 6379 5672; do check_port "$port"; done

section "8. CAC TIEN TRINH"
ps -eo pid,etime,args | grep -E \
    '[m]anage.py runserver|[m]anage.py runbridged|[D]MOJ Judge|[d]moj.*judge01' || true

section "9. CAC TRANG WEB"
.venv/bin/python - <<'PY'
import urllib.request
for path in [
    "/", "/accounts/login/", "/accounts/register/",
    "/admin/", "/problems/", "/contests/", "/submissions/"
]:
    url = "http://127.0.0.1:8000" + path
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "HVOJ-Audit/1.0"})
        with urllib.request.urlopen(req, timeout=5) as r:
            print(f"[HTTP {r.status}] {path}")
    except Exception as e:
        print(f"[LOI] {path}: {type(e).__name__}: {e}")
PY

section "10. EXECUTABLE JUDGE"
for f in .venv/bin/dmoj .venv/bin/dmoj-cli /usr/local/bin/scratch-run; do
    if [ -x "$f" ]; then echo "[OK] $f"; else echo "[THIEU] $f"; fi
done
.venv/bin/python -m pip show dmoj 2>&1 | head -n 12
for cmd in python3 g++ gcc; do
    command -v "$cmd" || true
done
python3 --version 2>&1 || true
g++ --version 2>&1 | head -n 1 || true
g++-11 --version 2>&1 | head -n 1 || true

section "11. CAU HINH VA BIEN MOI TRUONG"
ls -l judge01.yml local_settings.py start_judge01_background.sh 2>&1 || true
grep -nE '^(DEBUG|SECRET_KEY|ALLOWED_HOSTS|SECURE_|SESSION_COOKIE_SECURE|CSRF_COOKIE_SECURE)' \
    local_settings.py settings.py 2>/dev/null | \
    sed -E "s/(SECRET_KEY[[:space:]]*=[[:space:]]*).*/\1'[HIDDEN]'/"
echo "[INFO] Không in khóa judge hoặc mật khẩu để tránh lộ thông tin."

section "12. LOI GAN DAY TRONG LOG"
for f in logs/bridge.log logs/judge01.log logs/auto_repair.log; do
    if [ -f "$f" ]; then
        echo "--- $f ---"
        grep -iE 'error|exception|traceback|refused|timeout|failed|critical' "$f" \
            | tail -n 25 || true
    else
        echo "[INFO] Chưa có $f"
    fi
done

section "KET THUC"
echo "Báo cáo đầy đủ: $REPORT"
echo "Đã hoàn thành kiểm tra. Những mục [LOI]/[THIEU]/[CAN XEM] cần được phân loại trước khi sửa."
