"""Check every Roblox/Luau API name in the lab's Luau against the vault's dated API snapshot.

    python tools/api_check_lab.py [src]

Reuses the LihFolk vault's checker (LihFolk Vault V2/_tools/api_check.py + roblox_api.json):
real classes for Instance.new, real services, enums and members, and no deprecated calls.
Exit 1 on any finding.
"""
import json
import os
import sys
from pathlib import Path

LAB = Path(__file__).resolve().parent.parent
TOOLS = LAB.parent.parent / "LihFolk Vault V2" / "_tools"

if not (TOOLS / "api_check.py").exists():
    print(f"skipped: vault API checker not found at {TOOLS}")
    sys.exit(0)
sys.path.insert(0, str(TOOLS))
import api_check  # noqa: E402

checker = api_check.Checker(json.load(open(api_check.SNAP, encoding="utf-8")))
root = Path(sys.argv[1]) if len(sys.argv) > 1 else LAB / "src"
findings = files = 0
for d, _, fs in os.walk(root):
    for f in sorted(fs):
        if not f.endswith((".luau", ".lua")):
            continue
        files += 1
        path = Path(d) / f
        code = path.read_text(encoding="utf-8")
        for kind, sym, msg, off in checker.check(code, False):
            print(f"{path.relative_to(LAB)}:{code.count(chr(10), 0, off) + 1}  {kind}  {sym}  {msg}")
            findings += 1
print(f"API check: {files} files, {findings} finding(s)")
sys.exit(1 if findings else 0)
