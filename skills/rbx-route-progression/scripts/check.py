import argparse
from collections import defaultdict, deque
import json
from pathlib import Path
import sys


def require(condition, message):
    if not condition:
        raise ValueError(message)


def nonempty(items, label):
    require(isinstance(items, list) and len(items) > 0, f"Record at least one {label}")
    return items


def check(d):
    """Find unreachable objectives in a gated map."""
    outgoing = defaultdict(list)
    for edge in nonempty(d["edges"], "connection"):
        outgoing[edge["from"]].append(edge)
    start = (d["start"], frozenset(d["grants"].get(d["start"], [])))
    queue, seen, reachable = deque([start]), {start}, set()
    while queue:
        zone, keys = queue.popleft()
        reachable.add(zone)
        for edge in outgoing[zone]:
            if set(edge["requires"]) <= keys:
                target = edge["to"]
                state = target, keys.union(d["grants"].get(target, []))
                if state not in seen:
                    require(len(seen) < 50000, "Route search exceeded 50,000 states")
                    seen.add(state)
                    queue.append(state)
    missing = set(nonempty(d["goals"], "goal")) - reachable
    return [f"Unreachable goal: {goal}" for goal in sorted(missing)], [f"Reachable zones: {', '.join(sorted(reachable))}"]


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
