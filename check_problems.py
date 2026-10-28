from pathlib import Path
import sys, yaml, zipfile

root = Path("/home/huy/hvoj/problem_data")
errors = 0
count = 0

if not root.is_dir():
    sys.exit(f"LOI: Khong co thu muc {root}")

for d in sorted(root.iterdir()):
    if not d.is_dir():
        continue
    f = d / "init.yml"
    if not f.is_file():
        continue
    count += 1
    try:
        data = yaml.safe_load(f.read_text(encoding="utf-8"))
        if not isinstance(data, dict):
            raise ValueError("init.yml khong hop le")

        archive = data.get("archive")
        if archive:
            zpath = (d / archive).resolve()
            if not zpath.is_relative_to(d.resolve()) or not zpath.is_file():
                raise ValueError(f"Thieu archive: {archive}")
            if not zipfile.is_zipfile(zpath):
                raise ValueError(f"ZIP khong hop le: {archive}")
            with zipfile.ZipFile(zpath) as z:
                bad = z.testzip()
                if bad:
                    raise ValueError(f"ZIP bi loi: {bad}")
        elif not data.get("test_cases"):
            raise ValueError("Khong co archive hoac test_cases")

        print(f"[OK] {d.name}")
    except Exception as e:
        errors += 1
        print(f"[LOI] {d.name}: {e}")

print(f"Tong de: {count}; Loi: {errors}")
sys.exit(1 if errors else 0)
