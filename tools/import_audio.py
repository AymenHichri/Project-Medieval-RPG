"""Builds the game's audio copies from the original downloads (PROJECT_PLAN.md Phase 7A).

Reads tools/audio_sources.csv (one row per target file) and writes processed copies to
assets/audio/<target>. The originals in assests/audio_sources/ are only READ (the zips are
opened in place; nothing is extracted next to them).

Per row:
- `start_s` / `end_s` cut the source (seconds; empty = from the start / to the end).
- `loop`:  `smpl`  = loop the file between the loop points of its WAV `smpl` chunk (the copy ends at
                     the loop end; the loop start becomes `loop_offset` in the .import file);
           `whole` = loop the whole cut; `crossfade_s` > 0 bakes a crossfade from the cut's end into
                     its start so the seam is smooth (a timing edit);
           `no`    = one-shot (jingles, SFX).
- `filters`: an optional ffmpeg audio filter chain applied first (e.g. pitch down + low-pass to
  darken the Kenney UI sounds); only the filters in ALLOWED_FILTERS.
- `fade_in_s` / `fade_out_s` add fades; `gain` is `lufs:<target>` (integrated loudness, EBU R128)
  or `db:<gain>`; empty = unchanged.
Music/jingles (.ogg) are Ogg Vorbis q6, 44.1 kHz stereo; SFX (.wav) are 16-bit mono 44.1 kHz WAV
(AUDIO_GUIDELINES.md §4). For .ogg targets the [params] loop / loop_offset of the .import file are
written, keeping the rest of an existing .import (its uid).

Needs ffmpeg with libvorbis (env FFMPEG, else `ffmpeg` on PATH, else the copy bundled with
ImageMagick on Windows). Under WSL a Windows ffmpeg.exe gets Windows paths (wslpath -w).

Usage (from the project root):
    python -I tools/import_audio.py              # (re)build every target
    python -I tools/import_audio.py --if-missing # build only targets that don't exist yet
Exit code 1 on any error. Also reports slice IDs (AUDIO_CATALOG.md §C) that have no row.
"""
import csv
import os
import re
import shutil
import struct
import subprocess
import sys
import tempfile
import wave
import zipfile
import audioop

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCES = os.path.join(ROOT, "assests", "audio_sources")
OUT = os.path.join(ROOT, "assets", "audio")
TABLE = os.path.join(ROOT, "tools", "audio_sources.csv")
WINDOWS_FFMPEG = "/mnt/c/Program Files/ImageMagick-7.1.0-Q16-HDRI/ffmpeg.exe"
SOURCE_EXTS = (".wav", ".ogg")
# ffmpeg filters a `filters` cell may use (an allow-list: the table is data, not a command line).
ALLOWED_FILTERS = {"asetrate", "aresample", "lowpass", "highpass", "aecho", "volume", "atempo", "equalizer"}
TARGET_EXTS = (".wav", ".ogg")
# Slice IDs (AUDIO_CATALOG.md §C) reported when no row produces them.
SLICE_IDS = [
    "mus_menu", "mus_town_hamlet", "mus_dungeon_graveyard", "mus_battle",
    "jng_victory", "jng_gameover", "jng_levelup",
    "sfx_ui_focus", "sfx_ui_confirm", "sfx_ui_cancel", "sfx_ui_open", "sfx_ui_tick",
    "sfx_footsteps_stone", "sfx_footsteps_grass", "sfx_footsteps_mud",
    "sfx_combat_swing", "sfx_combat_hit", "sfx_combat_crit", "sfx_combat_miss",
    "sfx_magic_cast", "sfx_magic_fire", "sfx_magic_heal",
    "sfx_enemies_wolf_howl", "sfx_enemies_skeleton_rattle", "sfx_enemies_goblin_shriek",
    "amb_village_wind_loop", "amb_graveyard_wind_crows_loop",
    "sfx_reward_gold", "sfx_reward_item", "sfx_progress_levelup", "sfx_progress_rest",
]


class ImportError_(Exception):
    pass


def find_ffmpeg() -> str:
    if os.environ.get("FFMPEG"):
        return os.environ["FFMPEG"]
    found = shutil.which("ffmpeg")
    if found:
        return found
    if os.path.exists(WINDOWS_FFMPEG):
        return WINDOWS_FFMPEG
    raise ImportError_("ffmpeg not found (set FFMPEG)")


FFMPEG = ""


def ff_path(path: str) -> str:
    """A path the ffmpeg binary understands (Windows path for a Windows exe under WSL)."""
    if FFMPEG.lower().endswith(".exe") and os.name != "nt":
        return subprocess.run(["wslpath", "-w", path], capture_output=True, text=True, check=True).stdout.strip()
    return path


def ffmpeg(args: list) -> str:
    proc = subprocess.run([FFMPEG, "-hide_banner", "-nostdin"] + args, capture_output=True, text=True,
                          encoding="utf-8", errors="replace")
    if proc.returncode != 0:
        raise ImportError_("ffmpeg failed: " + proc.stderr.strip().splitlines()[-1] if proc.stderr else "ffmpeg failed")
    return proc.stderr


# --- WAV helpers ------------------------------------------------------------------------------

def wav_info(path: str) -> dict:
    """Format, data offset/size and smpl loop points of a PCM WAV."""
    info = {"loops": []}
    with open(path, "rb") as f:
        riff, _size, wave_id = struct.unpack("<4sI4s", f.read(12))
        if riff != b"RIFF" or wave_id != b"WAVE":
            raise ImportError_("not a WAV file")
        while True:
            head = f.read(8)
            if len(head) < 8:
                break
            cid, csize = struct.unpack("<4sI", head)
            pos = f.tell()
            if cid == b"fmt ":
                tag, ch, rate, _bps, align, bits = struct.unpack("<HHIIHH", f.read(16))
                info.update(tag=tag, channels=ch, rate=rate, align=align, width=bits // 8)
            elif cid == b"data":
                info.update(data_pos=pos, data_size=csize)
            elif cid == b"smpl":
                body = f.read(csize)
                count = struct.unpack("<I", body[28:32])[0]
                for i in range(count):
                    _cue, _typ, start, end, _frac, _n = struct.unpack("<6I", body[36 + 24 * i:60 + 24 * i])
                    info["loops"].append((start, end))
            f.seek(pos + csize + (csize & 1))
    if info.get("tag") not in (1, 0xFFFE) or "data_pos" not in info:
        raise ImportError_("unsupported WAV (PCM only)")
    info["frames"] = info["data_size"] // info["align"]
    return info


def read_frames(path: str, info: dict, start: int, count: int) -> bytes:
    with open(path, "rb") as f:
        f.seek(info["data_pos"] + start * info["align"])
        return f.read(count * info["align"])


def ramp(pcm: bytes, width: int, align: int, rising: bool, steps: int = 400) -> bytes:
    """Linear fade in or out, applied in `steps` short blocks (audioop.mul has no per-sample ramp)."""
    frames = len(pcm) // align
    out = bytearray()
    for s in range(steps):
        a = frames * s // steps
        b = frames * (s + 1) // steps
        g = (s + 0.5) / steps
        out += audioop.mul(pcm[a * align:b * align], width, g if rising else 1.0 - g)
    return bytes(out)


def write_wav(path: str, info: dict, pcm: bytes) -> None:
    with wave.open(path, "wb") as w:
        w.setnchannels(info["channels"])
        w.setsampwidth(info["width"])
        w.setframerate(info["rate"])
        w.writeframes(pcm)


def cut_wav(src: str, dst: str, row: dict) -> float:
    """Writes the cut (and crossfade) of `src` to `dst`. Returns loop_offset in seconds."""
    info = wav_info(src)
    rate, align, width = info["rate"], info["align"], info["width"]
    frames = info["frames"]
    start = int(round(float(row["start_s"] or 0) * rate))
    end = int(round(float(row["end_s"]) * rate)) if row["end_s"] else frames
    loop_offset = 0.0
    if row["loop"] == "smpl":
        if not info["loops"]:
            raise ImportError_("loop=smpl but the file has no smpl loop")
        loop_start, loop_end = info["loops"][0]
        end = min(frames, loop_end + 1)
        loop_offset = max(0.0, (loop_start - start) / rate)
    if not 0 <= start < end <= frames:
        raise ImportError_(f"bad cut {start}..{end} of {frames} frames")
    pcm = read_frames(src, info, start, end - start)
    xfade = int(round(float(row["crossfade_s"] or 0) * rate))
    if xfade > 0:
        if row["loop"] != "whole":
            raise ImportError_("crossfade_s needs loop=whole")
        if end + xfade > frames:
            raise ImportError_("not enough audio after end_s for the crossfade")
        head = pcm[:xfade * align]
        after = read_frames(src, info, end, xfade)
        mixed = audioop.add(ramp(head, width, align, True), ramp(after, width, align, False), width)
        pcm = mixed + pcm[xfade * align:]
    write_wav(dst, info, pcm)
    return loop_offset


# --- ffmpeg stages ----------------------------------------------------------------------------

def fade_filters(row: dict, duration: float) -> list:
    filters = []
    if row["fade_in_s"]:
        filters.append(f"afade=t=in:st=0:d={float(row['fade_in_s'])}")
    if row["fade_out_s"]:
        d = float(row["fade_out_s"])
        filters.append(f"afade=t=out:st={max(0.0, duration - d):.3f}:d={d}")
    return filters


def integrated_lufs(path: str, filters: list) -> float:
    chain = ",".join(filters + ["ebur128"])
    log = ffmpeg(["-i", ff_path(path), "-af", chain, "-f", "null", "-"])
    summary = log[log.rfind("Summary:"):]
    m = re.search(r"I:\s+(-?[\d.]+) LUFS", summary)
    if not m or float(m.group(1)) <= -70:
        raise ImportError_("could not measure loudness (too short? use db:<gain>)")
    return float(m.group(1))


def duration_of(path: str) -> float:
    log = ffmpeg(["-i", ff_path(path), "-f", "null", "-"])
    times = re.findall(r"time=(\d+):(\d+):([\d.]+)", log)
    if not times:
        raise ImportError_("could not read the duration")
    h, m, s = times[-1]
    return int(h) * 3600 + int(m) * 60 + float(s)


def encode(src: str, dst: str, row: dict) -> None:
    extra = [f.strip() for f in (row.get("filters") or "").split(",") if f.strip()]
    for f in extra:
        if f.split("=")[0] not in ALLOWED_FILTERS:
            raise ImportError_(f"filter not allowed: {f}")
    duration = wav_info(src)["frames"] / wav_info(src)["rate"] if src.lower().endswith(".wav") else duration_of(src)
    filters = extra + fade_filters(row, duration)
    gain = row["gain"].strip()
    if gain.startswith("lufs:"):
        filters.append(f"volume={float(gain[5:]) - integrated_lufs(src, filters):.2f}dB")
    elif gain.startswith("db:"):
        filters.append(f"volume={float(gain[3:]):.2f}dB")
    elif gain:
        raise ImportError_(f"bad gain {gain!r}")
    args = ["-y", "-i", ff_path(src)]
    if filters:
        args += ["-af", ",".join(filters)]
    if dst.endswith(".ogg"):
        args += ["-ar", "44100", "-ac", "2", "-c:a", "libvorbis", "-q:a", "6"]
    else:
        args += ["-ar", "44100", "-ac", "1", "-c:a", "pcm_s16le", "-map_metadata", "-1"]
    ffmpeg(args + [ff_path(dst)])


def write_ogg_import(target: str, loop: bool, loop_offset: float) -> None:
    """Sets loop / loop_offset in the Ogg's .import file (Godot keeps [params] on reimport)."""
    path = target + ".import"
    params = {"loop": "true" if loop else "false", "loop_offset": f"{loop_offset:.4f}",
              "bpm": "0", "beat_count": "0", "bar_beats": "4"}
    if os.path.exists(path):
        with open(path, encoding="utf-8") as f:
            text = f.read()
        head = text.split("[params]")[0].rstrip() + "\n\n"
    else:
        head = '[remap]\n\nimporter="oggvorbisstr"\ntype="AudioStreamOggVorbis"\n\n'
    body = "".join(f"{k}={v}\n" for k, v in params.items())
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(head + "[params]\n\n" + body)


# --- main -------------------------------------------------------------------------------------

def process(row: dict, tmp: str) -> None:
    target = os.path.join(OUT, row["target"])
    src_ext = os.path.splitext(row["source_path"])[1].lower()
    if src_ext not in SOURCE_EXTS or os.path.splitext(target)[1].lower() not in TARGET_EXTS:
        raise ImportError_("only WAV/Ogg sources and targets are allowed (no MP3)")
    if row["loop"] not in ("smpl", "whole", "no"):
        raise ImportError_(f"bad loop {row['loop']!r}")
    os.makedirs(os.path.dirname(target), exist_ok=True)
    raw = os.path.join(tmp, "source" + src_ext)
    with zipfile.ZipFile(os.path.join(SOURCES, row["source_zip"])) as zf, zf.open(row["source_path"]) as s, open(raw, "wb") as d:
        shutil.copyfileobj(s, d)
    loop_offset = 0.0
    stage = raw
    if src_ext == ".wav":
        stage = os.path.join(tmp, "cut.wav")
        loop_offset = cut_wav(raw, stage, row)
    elif row["start_s"] or row["end_s"] or row["loop"] == "smpl" or row["crossfade_s"]:
        raise ImportError_("cuts and loop edits need a WAV source")
    encode(stage, target, row)
    if target.endswith(".ogg"):
        write_ogg_import(target, row["loop"] != "no", loop_offset)


def main() -> int:
    global FFMPEG
    if_missing = "--if-missing" in sys.argv
    with open(TABLE, newline="", encoding="utf-8") as f:
        rows = list(csv.DictReader(f))
    todo = [r for r in rows if not (if_missing and os.path.exists(os.path.join(OUT, r["target"])))]
    errors = 0
    if todo:
        try:
            FFMPEG = find_ffmpeg()
        except ImportError_ as e:
            print("import_audio:", e)
            return 1
    for row in todo:
        tmp = tempfile.mkdtemp(prefix="import_audio_")
        try:
            process(row, tmp)
            print(f"  ok   {row['target']}")
        except (ImportError_, OSError, KeyError, ValueError, zipfile.BadZipFile) as e:
            errors += 1
            print(f"  FAIL {row['target']}: {e}")
        finally:
            shutil.rmtree(tmp, ignore_errors=True)
    built = {re.sub(r"_\d+$", "", os.path.splitext(os.path.basename(r["target"]))[0]) for r in rows}
    missing = [i for i in SLICE_IDS if i not in built]
    print(f"import_audio: {len(todo) - errors} built, {len(rows) - len(todo)} up to date, {errors} failed")
    if missing:
        print("  slice IDs with no source yet: " + ", ".join(missing))
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
