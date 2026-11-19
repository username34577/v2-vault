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


def distance(a, b, size=3):
    return math.dist(vector(a, size), vector(b, size))


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


def check(d):
    """Find pose or grip jumps when a cutscene prop changes owner."""
    failures, notes = [], []
    for name, row in unique(d["handoffs"], "id").items():
        gap = distance(row["before"], row["after"])
        rotation = angle(row["forward_before"], row["forward_after"])
        notes.append(f"{name}: {gap:.3f} studs and {rotation:.2f} deg at handoff")
        if gap > number(d["max_translation"]) or rotation > number(d["max_angle_deg"]):
            failures.append(f"{name}: pose discontinuity at owner switch")
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
