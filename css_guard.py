from pathlib import Path
from urllib.request import Request, urlopen
from urllib.parse import urljoin, urlparse
from html.parser import HTMLParser
import subprocess
import sys

BASE = "http://127.0.0.1:8000/"
ROOT = Path("/home/huy/hvoj")

class Styles(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = []

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag.lower() == "link" and "stylesheet" in a.get("rel", "").lower():
            if a.get("href"):
                self.links.append(a["href"])

def fetch(url):
    req = Request(url, headers={"Cache-Control": "no-cache"})
    with urlopen(req, timeout=8) as r:
        return r.status, r.headers.get("Content-Type", ""), r.read()

def check_page(path):
    url = urljoin(BASE, path)
    try:
        status, ctype, body = fetch(url)
        print(f"[PAGE] {path}: HTTP {status}")
        parser = Styles()
        parser.feed(body.decode("utf-8", errors="replace"))
        css_urls = [
            urljoin(url, x) for x in parser.links
            if urlparse(urljoin(url, x)).netloc == urlparse(BASE).netloc
        ]
        if not css_urls:
            print(f"[WARN] Khong tim thay stylesheet trong HTML: {path}")
        failures = []
        for css in dict.fromkeys(css_urls):
            try:
                st, ct, data = fetch(css)
                if st != 200 or "text/css" not in ct.lower():
                    failures.append((css, f"HTTP {st}, {ct}"))
                elif not data.strip():
                    failures.append((css, "tep CSS rong"))
            except Exception as e:
                failures.append((css, str(e)))
        for css, why in failures:
            print(f"[LOI CSS] {css} -> {why}")
        if not failures and css_urls:
            print(f"[OK] {len(set(css_urls))} stylesheet")
        return failures
    except Exception as e:
        print(f"[LOI TRANG] {path}: {e}")
        return [(url, str(e))]

print("=== KIEM TRA CSS HVOJ ===")
problems = []
for page in ("/", "/admin/"):
    problems.extend(check_page(page))

if not problems:
    print("\nKhong phat hien loi tai cac URL CSS kiem tra.")
    print("Neu giao dien van loi, can kiem tra CSS bi sai noi dung hoac JavaScript.")
    sys.exit(0)

print("\n=== THU SUA AN TOAN: COLLECTSTATIC ===")
print("Sao luu cau hinh truoc; collectstatic co the cap nhat STATIC_ROOT.")
ans = input("Chay manage.py collectstatic --noinput? (y/N): ").strip().lower()
if ans != "y":
    print("Chua thay doi tep static.")
    sys.exit(1)

result = subprocess.run(
    [str(ROOT / ".venv/bin/python"), "manage.py", "collectstatic", "--noinput"],
    cwd=ROOT
)
if result.returncode:
    print("Collectstatic that bai; xem loi phia tren.")
    sys.exit(result.returncode)

print("\n=== KIEM TRA LAI ===")
remaining = []
for page in ("/", "/admin/"):
    remaining.extend(check_page(page))

if remaining:
    print("\nVan con loi. Khong tu ghi de CSS bang noi dung phỏng đoán.")
    print("Can xem URL CSS bi loi va cau hinh static tuong ung.")
    sys.exit(1)

print("\nDa vuot qua kiem tra URL CSS sau collectstatic.")
