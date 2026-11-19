"""Print evaluated Blender mesh dimensions within calibrated head-space bands."""

import json
import math
from pathlib import Path
import sys

import bpy


def measure(config):
    units = float(config["units_to_studs"])
    if not math.isfinite(units) or units <= 0:
        raise ValueError("units_to_studs must be finite and positive")
    frame = bpy.data.objects[config["head_frame_object"]].matrix_world
    inverse_rotation = frame.to_quaternion().inverted()
    origin = frame.translation
    depsgraph = bpy.context.evaluated_depsgraph_get()
    results = []
    for band in config["sections"]:
        axis = ("X", "Y", "Z").index(band["axis"])
        lo, hi = float(band["lo"]), float(band["hi"])
        if not math.isfinite(lo) or not math.isfinite(hi) or lo >= hi:
            raise ValueError("Section bounds must be finite and increasing")
        points = []
        for name in dict.fromkeys(band["objects"]):
            source = bpy.data.objects[name]
            if source.type != "MESH":
                raise ValueError(f"Section object {name} is not a mesh")
            obj = source.evaluated_get(depsgraph)
            mesh = obj.to_mesh()
            try:
                vertices = [
                    (inverse_rotation @ (obj.matrix_world @ vertex.co - origin)) * units
                    for vertex in mesh.vertices
                ]
                points.extend(p for p in vertices if lo <= p[axis] <= hi)
                for edge in mesh.edges:
                    a, b = (vertices[index] for index in edge.vertices)
                    for boundary in (lo, hi):
                        if min(a[axis], b[axis]) < boundary < max(a[axis], b[axis]):
                            fraction = (boundary - a[axis]) / (b[axis] - a[axis])
                            points.append(a.lerp(b, fraction))
            finally:
                obj.to_mesh_clear()
        if not points:
            raise ValueError(f"Section {band['id']} has no sampled geometry")
        extents = [max(p[index] for p in points) - min(p[index] for p in points) for index in range(3)]
        results.append({"id": band["id"], "actual": [round(v, 6) for v in extents]})
    if not results:
        raise ValueError("Specify at least one section")
    return {"sections": results}


if __name__ == "__main__":
    args = sys.argv[sys.argv.index("--") + 1:]
    if len(args) != 1:
        raise ValueError("Pass one sections JSON file after --")
    print(json.dumps(measure(json.loads(Path(args[0]).read_text(encoding="utf-8-sig")))))
