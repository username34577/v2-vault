"""Asset manifest for the VFX library: which generated textures and meshes the game ACTUALLY uses,
their hashes, and the Roblox asset ids you uploaded them as.

    python tools/vfx_manifest.py                         # rebuild library/manifest.json + src/shared/VFX/Assets.luau
    python tools/vfx_manifest.py --stage upload/         # copy ONLY the files still needing upload into upload/
    python tools/vfx_manifest.py --set sim:eclipse_paint=rbxassetid://123 --set sim:ring=rbxassetid://456
    python tools/vfx_manifest.py --strict                # exit 1 if anything used has no id or a stale id (release gate)

Why: roblox-vfx generates ~2,600 library textures, but a game needs the dozen its kits reference.
This walks library/kits/*.assets.json (studio_kit.js output) and library/recipes/*.json, and tracks
only those. Uploading the library wholesale is never needed.

It also replaces roblox-vfx's missing tools/sync_vt.py (referenced by sim/studio_kit.js, not shipped):
  sim:<id>__vt  Beam/Trail textures: Roblox runs the image HEIGHT along the beam, the sim runs WIDTH,
                so the kit asks for a transposed copy.
  sim:<id>__em  SurfaceAppearance emissive masks: Roblox ignores the ColorMap alpha, so the kit asks
                for a premultiplied copy (RGB x alpha, black where transparent).
Derived files are written to library/derived/; the skill folder is never modified.

Ids you set are kept across runs. If a file's sha256 changes after upload, its status becomes
"stale" (re-upload, then --set the new id).
"""
import argparse
import datetime
import hashlib
import json
import os
import shutil
import sys
from pathlib import Path

LAB = Path(__file__).resolve().parent.parent
LIB = LAB / "library"
MANIFEST = LIB / "manifest.json"
DERIVED = LIB / "derived"
ASSETS_LUAU = LAB / "src" / "shared" / "VFX" / "Assets.luau"


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 16), b""):
            h.update(chunk)
    return h.hexdigest()


def derive(base_png, out_png, mode):
    from PIL import Image  # Pillow: already a roblox-vfx prerequisite

    im = Image.open(base_png).convert("RGBA")
    if mode == "vt":
        im = im.transpose(Image.Transpose.TRANSPOSE)
    elif mode == "em":
        px = im.load()
        out = Image.new("RGB", im.size)
        po = out.load()
        for y in range(im.size[1]):
            for x in range(im.size[0]):
                r, g, b, a = px[x, y]
                po[x, y] = (r * a // 255, g * a // 255, b * a // 255)
        im = out
    out_png.parent.mkdir(parents=True, exist_ok=True)
    im.save(out_png)


def resolve_texture(sim_id, tex_dir):
    """sim:<name>[__vt|__em] -> (path or None, source note)."""
    name = sim_id[4:]
    for suffix, mode in (("__vt", "vt"), ("__em", "em")):
        if name.endswith(suffix):
            base = tex_dir / (name[: -len(suffix)] + ".png")
            if not base.exists():
                return None, f"missing base texture {base.name} (run the roblox-vfx texture generators)"
            out = DERIVED / (name + ".png")
            if not out.exists() or out.stat().st_mtime < base.stat().st_mtime:
                derive(base, out, mode)
            return out, f"derived ({'transposed' if mode == 'vt' else 'premultiplied'}) from {base.name}"
    p = tex_dir / (name + ".png")
    return (p, "generated") if p.exists() else (None, f"missing {p.name} (run the roblox-vfx texture generators)")


def resolve_mesh(sim_id, sim_dir, fbx_dir):
    name = sim_id[4:]
    fbx = fbx_dir / (name + ".fbx")
    obj = sim_dir / "meshes" / (name + ".obj")
    if fbx.exists():
        return fbx, "fbx (upload this)"
    if obj.exists():
        return None, f"only {obj.name} exists: convert with sim/mesh/obj_to_fbx.py (Blender) before upload"
    return None, "missing: run the Blender mesh generators (sim/mesh/make_*.py)"


def portable(path, skill):
    """Store paths relative to the lab or as <skill>/..., never machine-specific absolute paths."""
    if not path:
        return None
    path = Path(path).resolve()
    skill = Path(skill).expanduser().resolve()
    if LAB in path.parents:
        return os.path.relpath(path, LAB).replace(os.sep, "/")
    if skill in path.parents:
        return "<skill>/" + os.path.relpath(path, skill).replace(os.sep, "/")
    return str(path)


def local(file, skill):
    if file.startswith("<skill>/"):
        return Path(skill).expanduser() / file[len("<skill>/"):]
    return LAB / file


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--skill", default=os.environ.get("ROBLOX_VFX_SKILL", str(Path.home() / ".claude" / "skills" / "roblox-vfx")))
    ap.add_argument("--fbx-dir", default=None, help="where FBX meshes are (default <skill>/sim/mesh/assets/meshes_fbx)")
    ap.add_argument("--set", action="append", default=[], metavar="SIMID=rbxassetid://N")
    ap.add_argument("--stage", help="copy files that still need uploading into this folder")
    ap.add_argument("--strict", action="store_true")
    a = ap.parse_args()

    sim_dir = Path(a.skill).expanduser() / "sim"
    tex_dir = sim_dir / "textures"
    fbx_dir = Path(a.fbx_dir) if a.fbx_dir else sim_dir / "mesh" / "assets" / "meshes_fbx"
    old = json.loads(MANIFEST.read_text(encoding="utf-8")) if MANIFEST.exists() else {"assets": {}}

    for s in a.set:
        sid, _, rid = s.partition("=")
        if not sid.startswith("sim:") or not rid.startswith("rbxassetid://") or not rid[13:].isdigit():
            sys.exit(f"bad --set {s!r}: want sim:<id>=rbxassetid://<digits>")
        old["assets"].setdefault(sid, {})["rbxassetid"] = rid
        old["assets"][sid]["uploaded_sha256"] = None  # filled below from the current file

    used = {}  # sim id -> {"kind", "used_by": set}
    stock = {}
    for f in sorted((LIB / "kits").glob("*.assets.json")):
        kit = f.name[: -len(".assets.json")]
        need = json.loads(f.read_text(encoding="utf-8"))
        for kind, key in (("texture", "textures"), ("mesh", "meshes")):
            for sid in need.get(key, []):
                used.setdefault(sid, {"kind": kind, "used_by": set()})["used_by"].add(f"kit:{kit}")
    for f in sorted((LIB / "recipes").glob("*.json")):
        rec = json.loads(f.read_text(encoding="utf-8"))
        for ref in rec.get("texture_refs", []):
            if ref.startswith("rbxasset://"):
                stock.setdefault(ref, set()).add(f"recipe:{rec['name']}")
            elif ref.startswith("sim:"):
                used.setdefault(ref, {"kind": "texture", "used_by": set()})["used_by"].add(f"recipe:{rec['name']}")

    assets = {}
    for sid in sorted(used):
        info = used[sid]
        prev = old["assets"].get(sid, {})
        if info["kind"] == "texture":
            path, source = resolve_texture(sid, tex_dir)
        else:
            path, source = resolve_mesh(sid, sim_dir, fbx_dir)
        digest = sha256(path) if path else None
        rid = prev.get("rbxassetid")
        up_sha = prev.get("uploaded_sha256")
        if rid and up_sha is None and digest:
            up_sha = digest  # just --set: the current file is what was uploaded
        if not path:
            status = "missing-source"
        elif not rid:
            status = "needs-upload"
        elif up_sha and digest != up_sha:
            status = "stale"
        else:
            status = "uploaded"
        assets[sid] = {
            "kind": info["kind"],
            "used_by": sorted(info["used_by"]),
            "file": portable(path, a.skill),
            "source": source,
            "sha256": digest,
            "rbxassetid": rid,
            "uploaded_sha256": up_sha,
            "status": status,
            "note": prev.get("note", ""),
        }

    lib_count = len(list((tex_dir / "lib").rglob("*.png"))) if (tex_dir / "lib").exists() else 0
    counts = {}
    for v in assets.values():
        counts[v["status"]] = counts.get(v["status"], 0) + 1
    manifest = {
        "about": "Generated by tools/vfx_manifest.py. Edit only 'rbxassetid' (via --set) and 'note'.",
        "generated": datetime.date.today().isoformat(),
        "skill": "<skill> = the installed roblox-vfx skill folder (--skill, default ~/.claude/skills/roblox-vfx)",
        "library_textures_available": lib_count,
        "assets_used": len(assets),
        "status_counts": counts,
        "stock_textures": {k: sorted(v) for k, v in sorted(stock.items())},
        "assets": assets,
    }
    MANIFEST.write_text(json.dumps(manifest, indent=1) + "\n", encoding="utf-8")

    # Luau table for Kit.buildTemplate(assets, parent): only ids that are uploaded and current.
    tex = [(k, v["rbxassetid"]) for k, v in assets.items() if v["kind"] == "texture" and v["status"] == "uploaded"]
    mesh = [(k, v["rbxassetid"]) for k, v in assets.items() if v["kind"] == "mesh" and v["status"] == "uploaded"]
    lines = [
        "-- GENERATED by tools/vfx_manifest.py from library/manifest.json. Do not hand-edit:",
        "-- record ids with  python tools/vfx_manifest.py --set sim:<id>=rbxassetid://<n>",
        "-- Shape expected by roblox-vfx kits: Kit.buildTemplate(Assets, parent).",
        "-- Only assets that are uploaded AND unchanged since upload are listed; the rest build blank.",
        "return {",
        "\ttextures = {",
        *[f'\t\t["{k}"] = "{v}",' for k, v in tex],
        "\t},",
        "\tmeshes = {",
        *[f'\t\t["{k}"] = "{v}",' for k, v in mesh],
        "\t},",
        "}",
        "",
    ]
    ASSETS_LUAU.parent.mkdir(parents=True, exist_ok=True)
    ASSETS_LUAU.write_text("\n".join(lines), encoding="utf-8")

    print(f"library textures available: {lib_count}; used by this game's kits and recipes: {len(assets)} "
          f"(+ {len(stock)} stock rbxasset textures, nothing to upload)")
    for st in ("uploaded", "needs-upload", "stale", "missing-source"):
        if counts.get(st):
            print(f"  {st:15s} {counts[st]}")
    if a.stage:
        dst = Path(a.stage)
        dst.mkdir(parents=True, exist_ok=True)
        n = 0
        for sid, v in assets.items():
            if v["status"] in ("needs-upload", "stale") and v["file"]:
                src = local(v["file"], a.skill)
                shutil.copy2(src, dst / (sid[4:].replace("/", "__") + src.suffix))
                n += 1
        print(f"staged {n} file(s) for upload in {dst}")
    if a.strict and any(v["status"] != "uploaded" for v in assets.values()):
        print("STRICT: some used assets are not uploaded or are stale")
        sys.exit(1)


if __name__ == "__main__":
    main()
