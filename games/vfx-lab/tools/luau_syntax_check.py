"""Rough Luau syntax check: block balance (function/do/if/repeat vs end/until) and bracket balance.

    python tools/luau_syntax_check.py src [more files or folders]

NOT a compiler: it catches the common breakages (a missing `end`, an unclosed bracket) when the
official Luau compiler is not available. When you have it, prefer:
    luau-compile --binary <file>   or   lune run <skill>/sim/tools/lune/compile_check.luau <file>
"""
import re, sys

KW_EXPR_PREV = {"=", "(", ",", "return", "{", "[", "and", "or", "not", "..", "then", "else", "==", "~=", "+", "-", "*", "/", "..=", "+=", "-=", "*=", "/=", "<", ">", "<=", ">=", "in", "do"}

def strip(src):
    out = []
    i, n = 0, len(src)
    while i < n:
        c = src[i]
        if src.startswith("--[[", i) or src.startswith("--[=[", i):
            m = re.match(r"--\[(=*)\[", src[i:])
            close = "]" + m.group(1) + "]"
            j = src.find(close, i)
            seg = src[i:j + len(close)]
            out.append("\n" * seg.count("\n")); i = j + len(close); continue
        if src.startswith("--", i):
            j = src.find("\n", i); j = n if j < 0 else j
            i = j; continue
        if src.startswith("[[", i) or re.match(r"\[=+\[", src[i:]):
            m = re.match(r"\[(=*)\[", src[i:])
            close = "]" + m.group(1) + "]"
            j = src.find(close, i)
            seg = src[i:j + len(close)]
            out.append(' "" ' + "\n" * seg.count("\n")); i = j + len(close); continue
        if c in "\"'`":
            j = i + 1
            depth_nl = 0
            while j < n and src[j] != c:
                if src[j] == "\\": j += 1
                elif c == "`" and src[j] == "{":
                    # interpolation: keep the expression
                    k = j + 1; d = 1
                    while k < n and d:
                        if src[k] == "{": d += 1
                        elif src[k] == "}": d -= 1
                        k += 1
                    j = k - 1
                if j < n and src[j] == "\n": depth_nl += 1
                j += 1
            out.append(' "" ' + "\n" * depth_nl); i = j + 1; continue
        out.append(c); i += 1
    return "".join(out)

def check(path):
    src = open(path, encoding="utf-8").read()
    s = strip(src)
    toks = re.findall(r"[A-Za-z_][A-Za-z_0-9]*|\d[\w.]*|\"\"|\.\.=?|[=~<>]=|[+\-*/]=|[(){}\[\],=<>+\-*/]|\n", s)
    stack = []
    line = 1
    prev = None
    errs = []
    for t in toks:
        if t == "\n":
            line += 1; continue
        if t in ("function", "do", "repeat"):
            if t == "do" and stack and stack[-1][0] in ("while", "for"):
                stack[-1] = ("do", stack[-1][1])
            else:
                stack.append((t, line))
        elif t in ("while", "for"):
            stack.append((t, line))
        elif t == "if":
            if prev in KW_EXPR_PREV and prev not in ("then", "else", "do"):
                stack.append(("ifexpr", line))
            elif prev in ("then", "else", "do") :
                stack.append(("if", line))
            else:
                stack.append(("if", line))
        elif t == "then":
            pass
        elif t == "else" or t == "elseif":
            pass
        elif t == "end":
            # pop any finished if-expressions first
            while stack and stack[-1][0] == "ifexpr":
                stack.pop()
            if not stack:
                errs.append(f"{path}:{line}: unexpected end")
            else:
                stack.pop()
        elif t == "until":
            while stack and stack[-1][0] == "ifexpr":
                stack.pop()
            if not stack or stack[-1][0] != "repeat":
                errs.append(f"{path}:{line}: unexpected until")
            else:
                stack.pop()
        prev = t
    rest = [x for x in stack if x[0] != "ifexpr"]
    for k, l in rest:
        errs.append(f"{path}:{l}: unclosed {k}")
    for o, c in ("()", "{}", "[]"):
        if s.count(o) != s.count(c):
            errs.append(f"{path}: bracket mismatch {o}{c}: {s.count(o)} vs {s.count(c)}")
    return errs

if __name__ == "__main__":
    import os
    files = []
    for p in sys.argv[1:]:
        if os.path.isdir(p):
            for d, _, fs in os.walk(p):
                files += [os.path.join(d, f) for f in sorted(fs) if f.endswith((".luau", ".lua"))]
        else:
            files.append(p)
    allerr = []
    for p in files:
        allerr += check(p)
    print("\n".join(allerr) if allerr else f"OK ({len(files)} files)")
    sys.exit(1 if allerr else 0)
