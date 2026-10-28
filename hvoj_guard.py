from pathlib import Path
import shutil
import sys
import zipfile
import yaml

ROOT = Path("/home/huy/hvoj/problem_data")
BACKUP_ROOT = Path("/home/huy/vnoj-site/problem_data")
errors = []
fixed = []

def inspect(folder):
    """Tra ve loi neu cau hinh hoac du lieu de khong hop le."""
    init = folder / "init.yml"
    if not init.is_file():
        return "thieu init.yml"

    try:
        data = yaml.safe_load(init.read_text(encoding="utf-8"))
    except Exception as e:
        return f"YAML khong doc duoc: {e}"

    if not isinstance(data, dict):
        return "init.yml khong phai YAML object"

    archive = data.get("archive")
    if archive:
        ap = (folder / archive).resolve()
        if not ap.is_relative_to(folder.resolve()):
            return "duong dan archive nam ngoai thu muc de"
        if not ap.is_file():
            return f"thieu archive: {archive}"
        if not zipfile.is_zipfile(ap):
            return f"archive khong phai ZIP hop le: {archive}"
        try:
            with zipfile.ZipFile(ap) as z:
                bad = z.testzip()
                if bad:
                    return f"ZIP bi hong tai: {bad}"
        except Exception as e:
            return f"khong doc duoc ZIP: {e}"
    else:
        cases = data.get("test_cases")
        if not isinstance(cases, list) or not cases:
            return "thieu archive hoac test_cases"
        for i, case in enumerate(cases, 1):
            if not isinstance(case, dict):
                return f"test {i} khong hop le"
            for key in ("in", "out"):
                name = case.get(key)
                if not isinstance(name, str):
                    return f"test {i} thieu ten tep {key}"
                path = (folder / name).resolve()
                if not path.is_relative_to(folder.resolve()):
                    return f"duong dan test {i} nam ngoai thu muc de"
                if not path.is_file():
                    return f"test {i} thieu tep {key}: {name}"
    return None

if not ROOT.is_dir():
    print(f"[LOI] Khong co thu muc de: {ROOT}")
    sys.exit(1)

# Chi tu phuc hoi khi ca thu muc de con thieu va ban nguon hop le.
if BACKUP_ROOT.is_dir():
    for src in sorted(BACKUP_ROOT.iterdir()):
        dst = ROOT / src.name
        if not src.is_dir() or dst.exists():
            continue
        problem = inspect(src)
        if problem is None:
            shutil.copytree(src, dst)
            fixed.append(src.name)
            print(f"[TU SUA] Da phuc hoi de {src.name} tu ban du phong.")

count = 0
for folder in sorted(ROOT.iterdir()):
    if not folder.is_dir():
        continue
    if not (folder / "init.yml").exists():
        continue
    count += 1
    problem = inspect(folder)
    if problem:
        errors.append((folder.name, problem))
        print(f"[LOI] {folder.name}: {problem}")
    else:
        print(f"[OK] {folder.name}")

print(f"\nTong de: {count}; Da tu sua: {len(fixed)}; Loi can xu ly: {len(errors)}")
if errors:
    print("Khong nen su dung cac de dang loi. Khong tu sua noi dung test hay dap an.")
    sys.exit(1)
print("KIEM TRA DAT.")
