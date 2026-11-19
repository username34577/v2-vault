import argparse
import json
import math
from pathlib import Path
import sys


def require(condition, message):
    if not condition:
        raise ValueError(message)


def nonempty(items, label):
    require(isinstance(items, list) and len(items) > 0, f"Record at least one {label}")
    return items


def number(value):
    require(type(value) in (int, float) and math.isfinite(value), "Expected a finite number")
    return value


def vector(items, size):
    require(isinstance(items, list) and len(items) == size, f"Expected a {size}-component vector")
    return [number(item) for item in items]


def angle(a, b):
    a, b = vector(a, 3), vector(b, 3)
    length = math.hypot(*a) * math.hypot(*b)
    require(length > 0, "Direction has zero length")
    cosine = sum(x * y for x, y in zip(a, b)) / length
    return math.degrees(math.acos(max(-1, min(1, cosine))))


def unique(items, key):
    result = {}
    for row in nonempty(items, key):
        name = row[key]
        require(isinstance(name, str) and name.strip() and name not in result, f"Missing or duplicate {key}: {name!r}")
        result[name] = row
    return result


def subtract(a, b):
    return [x - y for x, y in zip(vector(a, 3), vector(b, 3))]


def check(d):
    """Catch paper-thin locks and kinked tapers in sculpted hair."""
    failures, notes = [], []
    for name, lock in unique(d["locks"], "id").items():
        rows = nonempty(lock["stations"], "lock station")
        require(len(rows) >= 3 and not any(row.get("tip") for row in rows[:-1]), "Use 3+ stations and mark only the endpoint as tip")
        body = [row for row in rows if not row.get("tip")]
        for index, row in enumerate(rows):
            width, thickness = number(row["width"]), number(row["thickness"])
            require(width >= 0 and thickness >= 0 and (width > 0 or row.get("tip")), "Body width must be positive")
            if row in body and thickness / width < number(d["min_body_ratio"]):
                failures.append(f"{name} station {index}: thin cross-section ({thickness / width:.1%} of width)")
        bends = [angle(subtract(b["p"], a["p"]), subtract(c["p"], b["p"])) for a, b, c in zip(rows, rows[1:], rows[2:])]
        if max(bends) > number(d["max_bend_deg"]):
            failures.append(f"{name}: abrupt bend near station {bends.index(max(bends)) + 1}")
        if rows[-1].get("tip") and rows[-1]["width"] / max(row["width"] for row in body) > number(d["max_tip_width_ratio"]):
            failures.append(f"{name}: tip is too wide for the chosen taper")
        notes.append(f"{name}: maximum centerline bend {max(bends):.1f} deg")
    return failures, notes


def main():
    parser = argparse.ArgumentParser(description=check.__doc__)
    parser.add_argument("capture", type=Path)
    if "write_curve_report" in globals():
        parser.add_argument("--report", type=Path, help="Save an HTML motion-curve comparison")
    args = parser.parse_args()
    try:
        data = json.loads(args.capture.read_text(encoding="utf-8-sig"))
        require(isinstance(data, dict), "Expected a JSON object")
        data["_capture_dir"] = args.capture.resolve().parent
        findings, measurements = check(data)
        if getattr(args, "report", None):
            require(args.report.suffix.lower() == ".html", "Curve report must end in .html")
            require(args.report.resolve() != args.capture.resolve(), "Report must be separate from capture")
            write_curve_report(data, args.report, findings, measurements)
    except (OSError, ValueError, KeyError, TypeError, IndexError, ZeroDivisionError, OverflowError, AttributeError) as error:
        print(f"INVALID: {error}", file=sys.stderr)
        return 2
    for measurement in measurements:
        print(measurement)
    for finding in findings:
        print(f"FAIL: {finding}")
    print(f"{len(findings)} finding(s)." if findings else "PASS: recorded checks passed.")
    return int(bool(findings))


if __name__ == "__main__":
    sys.exit(main())
