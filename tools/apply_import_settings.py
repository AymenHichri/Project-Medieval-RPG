"""Per-folder texture import settings (Godot has no per-folder import presets).

Usage (from the project root, after a first `godot --headless --import`):
    python -I tools/apply_import_settings.py
then run `godot --headless --import` again to re-import the changed files.

Rules (ART_GUIDELINES.md §2):
- Pixel-art interface folders: mipmaps OFF (they are drawn 1:1 with Nearest filtering).
- Everything else keeps the project default (mipmaps ON, set in importer_defaults/texture).
Only `.import` sidecar files written by Godot inside the project are edited; source assets are untouched.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PIXEL_UI_DIRS = ["assets/vendor/gimbles", "assets/vendor/dfgui"]


def main() -> int:
    changed = 0
    for rel in PIXEL_UI_DIRS:
        for dirpath, _dirs, files in os.walk(os.path.join(ROOT, rel)):
            for name in files:
                if not name.endswith(".png.import"):
                    continue
                path = os.path.join(dirpath, name)
                with open(path, encoding="utf-8") as f:
                    text = f.read()
                new = re.sub(r"^mipmaps/generate=true$", "mipmaps/generate=false", text, flags=re.M)
                if new != text:
                    with open(path, "w", encoding="utf-8", newline="\n") as f:
                        f.write(new)
                    changed += 1
    print(f"apply_import_settings: {changed} .import files switched to mipmaps off")
    return 0


if __name__ == "__main__":
    sys.exit(main())
