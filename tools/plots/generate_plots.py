#!/usr/bin/env python3
"""Makes the other three tycoon plots (and their spawns) from Plot1.

Run from the repo root:   python3 tools/plots/generate_plots.py

Plot1 (src/Workspace/Map/Plots/Plot1.model.json) is the only plot anyone
edits. This script copies it three times, turned 90, 180, and 270 degrees
around the statue's center, so the four plots sit at the same distance from
the statue, each with its front doorway facing it:

  Plot1  toward -Z (in front of the statue)     PlotId 1
  Plot2  toward -X                              PlotId 2
  Plot3  toward +Z (behind the statue)          PlotId 3
  Plot4  toward +X                              PlotId 4

The spawn (src/Workspace/Map/SpawnLocation.model.json, between Plot1 and the
statue) is copied the same way to SpawnLocation2-4, so every plot has a
spawn in front of it. Players appear at a random one of the four.

Re-run this after changing Plot1 or the spawn (for example after
tools/house/generate_house.py). Do not hand-edit Plot2-4 or SpawnLocation2-4.
"""

import copy
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MAP = os.path.join(ROOT, "src", "Workspace", "Map")
PLOTS = os.path.join(MAP, "Plots")

# The statue's center (tools/statue/generate_statue.py STATUE_ORIGIN, x/z).
CENTER_X, CENTER_Z = 0, 44

# Quarter turns around the Y axis (row-major rotation matrices). Turn k moves
# Plot1's direction (-Z from the center) to the direction in the docstring.
TURNS = {
    1: [[0, 0, 1], [0, 1, 0], [-1, 0, 0]],  # 90 degrees: -Z -> -X
    2: [[-1, 0, 0], [0, 1, 0], [0, 0, -1]],  # 180 degrees: -Z -> +Z
    3: [[0, 0, -1], [0, 1, 0], [1, 0, 0]],  # 270 degrees: -Z -> +X
}


def matmul(a, b):
    return [[sum(a[i][k] * b[k][j] for k in range(3)) for j in range(3)] for i in range(3)]


def clean(v):
    v = round(v, 6)
    return int(v) if v == int(v) else v


def turn(node, rot):
    """Turns every CFrame in this instance tree around the statue's center."""
    cframe = node.get("properties", {}).get("CFrame", {}).get("CFrame")
    if cframe:
        x, y, z = cframe["position"]
        dx, dz = x - CENTER_X, z - CENTER_Z
        cframe["position"] = [
            clean(CENTER_X + rot[0][0] * dx + rot[0][2] * dz),
            y,
            clean(CENTER_Z + rot[2][0] * dx + rot[2][2] * dz),
        ]
        cframe["orientation"] = [[clean(v) for v in row] for row in matmul(rot, cframe["orientation"])]
    for child in node.get("children", []):
        turn(child, rot)


def write(path, data):
    with open(path, "w", encoding="utf-8") as f:
        f.write(json.dumps(data, indent=2, ensure_ascii=False) + "\n")


def main():
    with open(os.path.join(PLOTS, "Plot1.model.json"), encoding="utf-8") as f:
        plot1 = json.load(f)
    with open(os.path.join(MAP, "SpawnLocation.model.json"), encoding="utf-8") as f:
        spawn1 = json.load(f)

    for k, rot in TURNS.items():
        plot_id = k + 1
        plot = copy.deepcopy(plot1)
        plot.setdefault("attributes", {})["PlotId"] = plot_id
        turn(plot, rot)
        write(os.path.join(PLOTS, f"Plot{plot_id}.model.json"), plot)

        spawn = copy.deepcopy(spawn1)
        turn(spawn, rot)
        write(os.path.join(MAP, f"SpawnLocation{plot_id}.model.json"), spawn)
        print(f"Plot{plot_id} + SpawnLocation{plot_id} written")


if __name__ == "__main__":
    main()
