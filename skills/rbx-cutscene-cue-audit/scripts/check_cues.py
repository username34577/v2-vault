"""Check authored or observed cutscene events against an expected cue sheet."""

import argparse
from collections import defaultdict
import json
import math
from pathlib import Path
import sys


def seconds(value):
    if type(value) not in (int, float) or value < 0 or not math.isfinite(value):
        raise ValueError("Cue times and tolerances must be finite, nonnegative seconds")
    return value


def group_events(events, expected):
    groups = defaultdict(list)
    for event in events:
        key = event["track"], event["cue"]
        if any(not isinstance(item, str) or not item.strip() for item in key):
            raise ValueError("Track and cue must be nonempty strings")
        value = (seconds(event["time"]), seconds(event["tolerance"])) if expected else seconds(event["time"])
        groups[key].append(value)
    return {key: sorted(items) for key, items in groups.items()}


def run(path):
    with path.open(encoding="utf-8-sig") as source:
        sheet = json.load(source)
    expected = group_events(sheet["expected"], expected=True)
    actual = group_events(sheet["actual"], expected=False)
    if not expected:
        raise ValueError("Include at least one expected cue")
    failures = 0
    for track, cue in sorted(expected.keys() | actual.keys()):
        label = f"{track} / {cue}"
        wanted, seen = expected.get((track, cue), []), actual.get((track, cue), [])
        if len(wanted) != len(seen):
            print(f"FAIL {label}: expected {len(wanted)}, saw {len(seen)} occurrences")
            print(f"  Expected: {[time for time, _ in wanted]} s; actual: {seen} s")
            failures += 1
            continue
        for index, ((target, tolerance), measured) in enumerate(zip(wanted, seen), start=1):
            delta = measured - target
            failed = abs(delta) > tolerance and not math.isclose(abs(delta), tolerance, abs_tol=1e-12)
            status = "FAIL" if failed else "PASS"
            failures += failed
            print(f"{status} {label} #{index}: {measured:.3f}s (offset {delta:+.3f}s, allowed {tolerance:.3f}s)")
    return int(bool(failures))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("sheet", type=Path)
    args = parser.parse_args()
    try:
        return run(args.sheet)
    except (OSError, ValueError, TypeError, KeyError, OverflowError) as error:
        print(f"Invalid cue sheet: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
