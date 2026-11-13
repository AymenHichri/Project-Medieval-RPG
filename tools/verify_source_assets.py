"""Record or verify SHA-256 checksums of the original asset zips in assests/.

Usage (run from the project root, with `python -I`):
    python -I tools/verify_source_assets.py --record   # write tools/source_assets.sha256
    python -I tools/verify_source_assets.py            # verify, exit 1 on any mismatch
The script only READS files in assests/; it never writes there.
"""
import hashlib
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "assests")
DB = os.path.join(ROOT, "tools", "source_assets.sha256")


def sha256(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def current() -> dict:
    return {n: sha256(os.path.join(SRC, n)) for n in sorted(os.listdir(SRC)) if n.lower().endswith(".zip")}


def main() -> int:
    now = current()
    if "--record" in sys.argv:
        with open(DB, "w", encoding="utf-8", newline="\n") as f:
            for name, digest in now.items():
                f.write(f"{digest}  {name}\n")
        print(f"recorded {len(now)} checksums -> {DB}")
        return 0
    expected = {}
    with open(DB, encoding="utf-8") as f:
        for line in f:
            if line.strip():
                digest, name = line.rstrip("\n").split("  ", 1)
                expected[name] = digest
    bad = [n for n, d in expected.items() if now.get(n) != d]
    if bad:
        print("SOURCE ASSETS CHANGED OR MISSING:", ", ".join(bad))
        return 1
    extra = sorted(set(now) - set(expected))
    if extra:
        print("note: new zips not yet recorded:", ", ".join(extra))
    print(f"ok: {len(expected)} source zips unchanged")
    return 0


if __name__ == "__main__":
    sys.exit(main())
