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


def check(d):
    """Check measured risers, treads, and landings."""
    findings, measurements = [], []
    previous = None
    for step in nonempty(d["steps"], "step"):
        name, rise, tread = step["name"], number(step["rise"]), number(step["tread"])
        require(rise >= 0 and tread > 0, "Measured rise and tread must be nonnegative and positive")
        measurements.append(f"{name}: rise {rise:.2f}, tread {tread:.2f} studs")
        if rise > number(d["max_rise"]) or tread < number(d["min_tread"]):
            findings.append(f"{name} is too tall or shallow")
        if previous is not None and abs(rise - previous) > number(d["max_rise_change"]):
            findings.append(f"{name} changes rise by {abs(rise - previous):.2f} studs")
        previous = rise
    return findings, measurements


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
