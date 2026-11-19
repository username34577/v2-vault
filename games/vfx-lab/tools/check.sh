#!/usr/bin/env bash
# Full VFX validation for the lab (and any game using the same library layout).
#   bash tools/check.sh            # regenerate + validate everything; exit 1 on any failure
# Steps: author recipes -> verify_vfx -> emit VFXKit -> critic_gate on effects -> export kits ->
#        asset manifest -> Luau syntax check -> Roblox API check -> Lune gates (only if lune is installed).
# Needs the roblox-vfx skill (ROBLOX_VFX_SKILL, default ~/.claude/skills/roblox-vfx), Python 3.11+
# with Pillow, and Node.js.
set -uo pipefail
cd "$(dirname "$0")/.."
SKILL="${ROBLOX_VFX_SKILL:-$HOME/.claude/skills/roblox-vfx}"
fail=0
step() { printf '\n== %s\n' "$1"; }
run() { "$@" || { echo "FAILED: $*"; fail=1; }; }

[ -d "$SKILL" ] || { echo "roblox-vfx skill not found at $SKILL (set ROBLOX_VFX_SKILL)"; exit 1; }

step "author recipes (tools/author_recipes.py)"
run python3 tools/author_recipes.py

step "verify recipes (roblox-vfx verify_vfx.py; --lib is required even for one file)"
out=$(python3 "$SKILL/scripts/verify_vfx.py" --lib library/recipes); echo "$out"
echo "$out" | grep -q " 0 failure(s), 0 warning(s)" || { echo "FAILED: recipes not clean"; fail=1; }

step "emit VFXKit (roblox-vfx emit_luau.py)"
run python3 "$SKILL/scripts/emit_luau.py" --lib library/recipes src/shared/VFX/VFXKit.luau

step "critic gate on authored effects (roblox-vfx critic_gate.py)"
for f in library/effects/*.json; do
  echo "-- $f"
  run python3 "$SKILL/scripts/critic_gate.py" "$f"
done

step "export Studio kits (roblox-vfx sim/studio_kit.js)"
mkdir -p library/kits src/shared/VFX/Kits
for f in library/effects/*.json; do
  case "$f" in *.briefed.json) continue ;; esac  # investigation copies, not shipped
  base=$(basename "$f" .json)
  run node "$SKILL/sim/studio_kit.js" "$f" library/kits
  name=$(python3 -c "import json,re,sys; n=json.load(open(sys.argv[1])).get('name','Effect'); print(re.sub(r'[^A-Za-z0-9]','',n))" "$f")
  cp "library/kits/$base.luau" "src/shared/VFX/Kits/$name.luau"
  chars=$(wc -c < "library/kits/$base.luau")
  [ "$chars" -lt 200000 ] || { echo "FAILED: $base.luau is $chars chars (Roblox Source cap 200,000)"; fail=1; }
done

step "asset manifest (tools/vfx_manifest.py: used assets only, __vt/__em derived)"
run python3 tools/vfx_manifest.py --skill "$SKILL"

step "Luau syntax check (rough: block/bracket balance; not a compiler)"
run python3 tools/luau_syntax_check.py src

step "Roblox API names (vault snapshot: real classes/members/enums, nothing deprecated)"
run python3 tools/api_check_lab.py src

if command -v lune >/dev/null 2>&1; then
  step "Lune gates (roblox-vfx compile_check / build_check)"
  for k in library/kits/*.luau; do
    run lune run "$SKILL/sim/tools/lune/compile_check.luau" "$k"
    run lune run "$SKILL/sim/tools/lune/build_check.luau" "$k"
  done
else
  step "Lune gates: SKIPPED (lune not installed; run them on a machine that has it)"
fi

echo
if [ "$fail" = 0 ]; then echo "ALL CHECKS PASSED"; else echo "SOME CHECKS FAILED"; fi
exit "$fail"
