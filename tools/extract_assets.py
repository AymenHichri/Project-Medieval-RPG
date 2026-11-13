"""Copy the needed subsets of the downloaded asset zips into the Godot project.

Usage (from the project root):
    python -I tools/extract_assets.py            # extract (skips files that already exist with the same size)
    python -I tools/extract_assets.py --dry-run  # list what would be written

Rules (see PROJECT_PLAN.md, Phase 1):
- The zips in assests/ are only READ. Nothing is ever written into assests/.
- Each pack keeps its internal folder layout, so the vendor .tres/.tscn relative paths keep working.
- Skipped everywhere: per-frame PNG folders (frames/), *_smooth clips, _sizes/ copies, previews/,
  recolour masks, Tiled files, rendered sample maps, example scenes, and any GDScript outside addons/.
"""
from __future__ import annotations

import os
import sys
import zipfile
from typing import Callable

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "assests")
SOV = "assets/vendor/sovdigital"

Rule = Callable[[str], "str | None"]  # zip member name -> project-relative destination, or None to skip


def _common_skip(name: str) -> bool:
    parts = name.split("/")
    base = parts[-1]
    if name.endswith("/") or not base:
        return True
    if "frames" in parts or "_sizes" in parts or "previews" in parts or "recolour_masks" in parts:
        return True
    if "_smooth" in base:
        return True
    return False


def character_pack(pack_dir: str, characters: list[str], variants: dict[str, list[str]], with_effects: bool) -> Rule:
    """characters/<name>/{sheets,godot,<name>.json,moves/*}, chosen ColourVariations, optional effects/."""

    def rule(name: str) -> str | None:
        if _common_skip(name):
            return None
        parts = name.split("/")
        if len(parts) == 1 and parts[0] in ("LICENSE.txt", "README.txt"):
            return f"{SOV}/{pack_dir}/{name}"
        if parts[0] == "characters" and len(parts) > 2 and parts[1] in characters:
            if "weapon_trails" in parts:
                return None
            return f"{SOV}/{pack_dir}/{name}"
        if parts[0] == "ColourVariations" and len(parts) > 3:
            colour, char = parts[1], parts[2]
            if char in variants and colour in variants[char]:
                return f"{SOV}/{pack_dir}/{name}"
            return None
        if with_effects and parts[0] == "effects":
            return f"{SOV}/{pack_dir}/{name}"
        return None

    return rule


ENV_DIRS = {"animated", "atlases", "buildings", "decals", "destructibles", "grounds", "props", "terrain", "walls", "landmarks"}
ENV_ROOT_FILES = {"LICENSE.txt", "README.txt", "biome.json"}


def environment_pack(pack_dir: str, prefix: str, palettes: list[str]) -> Rule:
    """Environment kit at full size: root palette + selected ColourVariations; TileSet .tres from godot/."""

    def keep(rel: list[str]) -> bool:
        if len(rel) == 1:
            return rel[0] in ENV_ROOT_FILES
        if rel[0] in ENV_DIRS:
            return not rel[-1].endswith(".gd")
        if rel[0] == "godot" and len(rel) == 2 and rel[1].endswith("_tileset.tres"):
            return True
        return False

    def rule(name: str) -> str | None:
        if _common_skip(name) or not name.startswith(prefix):
            return None
        rel = name[len(prefix):].split("/")
        if rel[0] == "village" and prefix == "":  # the courtyard zip bundles the village pack in village/
            return None
        if rel[0] == "ColourVariations":
            if len(rel) > 2 and rel[1] in palettes and keep(rel[2:]):
                return f"{SOV}/{pack_dir}/{'/'.join(rel)}"
            return None
        if keep(rel):
            return f"{SOV}/{pack_dir}/{'/'.join(rel)}"
        return None

    return rule


def weather_rule(name: str) -> str | None:
    if _common_skip(name):
        return None
    parts = name.split("/")
    if len(parts) == 1 and parts[0] in ("LICENSE.txt", "README.txt"):
        return f"{SOV}/weather/{name}"
    if "fx_spawn" in parts or name.endswith(".gd"):
        return None  # vendor Fx autoload is not used (we keep 5 autoloads)
    if parts[0] == "overlays" or parts[0] == "godot":
        return f"{SOV}/weather/{name}"
    if parts[0] == "effects" and len(parts) > 1 and parts[1].startswith("lightning_"):
        return f"{SOV}/weather/{name}"
    return None


def necropolis_scripts_rule(name: str) -> str | None:
    """MIT-0 ambience + weather scripts/shaders -> addons/sovdigital/ (exempt from our strict typing)."""
    for sub in ("ambience", "weather"):
        p = f"godot/{sub}/"
        if name.startswith(p) and not name.endswith("/"):
            return f"addons/sovdigital/{sub}/{name[len(p):]}"
    return None


def gimbles_rule(name: str) -> str | None:
    prefix = "Gimbles_Dark_Fantasy_Kit_Sampler_Free_v1.0/"
    if not name.startswith(prefix) or name.endswith("/"):
        return None
    rel = name[len(prefix):]
    keep_prefixes = ("ui/2x/", "item_icons/64px/", "hud_icons/64px/", "portraits/framed/256px/",
                     "portraits/transparent/128px/", "backgrounds/1920x1080/", "palette/")
    if rel in ("ui/ui_index.json", "LICENSE.txt", "README.txt", "index.csv", "index.json") or rel.startswith(keep_prefixes):
        return f"assets/vendor/gimbles/{rel}"
    return None


def dfgui_rule(name: str) -> str | None:
    base = name.replace("\\", "/").split("/")[-1]
    if "/" in name.replace("\\", "/") or not base.startswith("dfgui_") or not base.endswith(".png"):
        return None  # screenshots/ are vendor previews only
    return f"assets/vendor/dfgui/1x/{base}"


def combine(*rules: Rule) -> Rule:
    def rule(name: str) -> str | None:
        for r in rules:
            dest = r(name)
            if dest:
                return dest
        return None

    return rule


JOBS: list[tuple[str, Rule]] = [
    ("KnightFreeSampler_v2.2.9.zip", character_pack("knight", ["knight"], {"knight": ["black", "gold"]}, False)),
    ("WolfFree_v2.0.5.zip", character_pack("wolf", ["wolf"], {"wolf": ["black"]}, False)),
    ("SkeletonFree_v1.2.6.zip", character_pack("skeleton", ["skeleton"], {"skeleton": ["charred"]}, True)),
    ("free-goblin-scout-goblinscoutfree-v2-0-2.zip", character_pack("goblin_scout", ["goblin-scout"], {}, False)),
    ("BladeAssassinBossFree_v1.3.1.zip",
     character_pack("blade_assassin", ["blade-assassin", "blade-assassin-phase-two"], {}, True)),
    ("WeatherEffectsFree_v1.1.0.zip", weather_rule),
    ("free-goblin-scout-castle-courtyard-free.zip", combine(
        environment_pack("castle_courtyard", "", ["ash", "slate"]),
        environment_pack("village", "village/", ["ash", "slate"]))),
    ("free-top-down-asset-pack-necropolis-free.zip", combine(
        environment_pack("necropolis", "", ["ash", "frost"]),
        necropolis_scripts_rule)),
    ("Gimbles_Dark_Fantasy_Kit_Sampler_Free_v1.0.zip", gimbles_rule),
    ("All Assets.zip", dfgui_rule),
]


def main() -> int:
    dry = "--dry-run" in sys.argv
    total_files = 0
    total_bytes = 0
    for zip_name, rule in JOBS:
        path = os.path.join(SRC, zip_name)
        if not os.path.isfile(path):
            print(f"MISSING source zip: {zip_name}")
            return 1
        n = 0
        size = 0
        with zipfile.ZipFile(path) as z:
            for info in z.infolist():
                dest = rule(info.filename)
                if not dest:
                    continue
                if ".." in dest.split("/"):
                    raise ValueError(f"unsafe path in {zip_name}: {info.filename}")
                out = os.path.join(ROOT, *dest.split("/"))
                n += 1
                size += info.file_size
                if dry:
                    print(f"  {dest}")
                    continue
                if os.path.isfile(out) and os.path.getsize(out) == info.file_size:
                    continue
                os.makedirs(os.path.dirname(out), exist_ok=True)
                with z.open(info) as src, open(out, "wb") as dst:
                    while True:
                        chunk = src.read(1 << 20)
                        if not chunk:
                            break
                        dst.write(chunk)
        print(f"{zip_name}: {n} files, {size / 1e6:.1f} MB")
        total_files += n
        total_bytes += size
    print(f"TOTAL: {total_files} files, {total_bytes / 1e6:.1f} MB{' (dry run)' if dry else ''}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
