#!/usr/bin/env python3
"""Builds the house security parts (House Raid) in Plot1.

Run from the repo root:   python3 tools/security/generate_security.py
Then run:                 python3 tools/plots/generate_plots.py

Three plot children (names fixed by Shared/HouseRaid.luau), all part of the
"Build Walls" purchase (Config.Builds Walls Parts), so they appear with the
walls and are hidden on unclaimed plots:

  SecurityPad   round green floor button inside the house, left of the
                doorway, in a dark metal ring. HouseSecurityService turns it
                red (and lights it) while the bars are up.
  SecurityBars  Model: red metal bars across the front doorway (x -8..8 at
                z -10.5) with a top, middle and bottom rail. Saved in the DOWN
                position, sunk below the floor; HouseSecurityService raises
                them by the model's RiseStuds attribute so they fill the
                doorway from the floor up to the door frame (y 2..12.4).
                Solid on the server; the owner's client turns that off
                locally (HouseSecurity.client).
  TrophyStash   gold floor pad with a purple ring in the back-right corner,
                labeled "STASH STOLEN TROPHIES HERE" (TheftService uses it).

Only these three children are rewritten (in place, or added at the end);
the rest of the plot file is left exactly as it is. Edit the numbers here
and re-run instead of hand-editing the JSON.

Coordinates are Plot1's (world) coordinates. The floor's top is y = 2, the
front wall's center is z = -10.5 (the room is toward -Z), the doorway is
x -8..8 up to y 13 (its gray frame posts are at x +-7.4..8, the frame top
y 12.4..13).
"""

import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PLOT_FILE = os.path.join(ROOT, "src", "Workspace", "Map", "Plots", "Plot1.model.json")

FLOOR = 2.0
DOOR_Z = -10.5  # the front wall's center line
FRAME_INNER = 7.4  # the door frame posts' inner faces are at x = +-7.4
BARS_TOP = 12.4  # bottom of the door frame's top piece
BAR_COUNT = 10
BAR_SPACING = 1.5  # center to center (gaps of 1.0: nobody fits through)
BAR_DIAMETER = 0.5
RAIL_HEIGHT = 0.6
RAIL_DEPTH = 0.8
RISE = BARS_TOP - FLOOR + 0.6  # down position: the whole gate is below the floor (top at y 1.4)

PAD_POS = (-13, 2.2, -16)  # 4.5 studs in, 5 left of the doorway: not on the walk-in line
PAD_DIAMETER = 5
STASH_POS = (21, 2.2, -64)  # back-right corner: clear of stairs, Trophy Case, BuildButton4
STASH_DIAMETER = 7

IDENTITY = [[1, 0, 0], [0, 1, 0], [0, 0, 1]]
UPRIGHT = [[0, -1, 0], [1, 0, 0], [0, 0, 1]]  # a Cylinder's axis (X) pointing up, like the other pads

GREEN = (40, 200, 70)  # keep equal to Config.HouseSecurityPadOpenColor
PAD_RING = (60, 64, 70)
BAR_RED = (190, 28, 28)
RAIL_RED = (140, 18, 22)
GOLD = (255, 196, 40)
PURPLE = (120, 50, 190)
OUTLINE = [0.157, 0.11, 0.078]


def r(x):
    x = round(x, 3)
    return int(x) if x == int(x) else x


def part(name, size, pos, color, material="SmoothPlastic", rot=None, shape=None, touch=True, children=None):
    props = {
        "Size": [r(s) for s in size],
        "CFrame": {"CFrame": {"position": [r(c) for c in pos], "orientation": rot or IDENTITY}},
        "Color": {"Color3uint8": list(color)},
        "Anchored": True,
        "Material": material,
        "TopSurface": "Smooth",
        "BottomSurface": "Smooth",
    }
    if shape:
        props["Shape"] = shape
    if not touch:
        props["CanTouch"] = False
    node = {"name": name, "className": "Part", "properties": props}
    if children:
        node["children"] = children
    return node


def ring(name, pos, diameter, color, material="SmoothPlastic"):
    """The darker outline ring under a pad (like the other pads' rings)."""
    x, y, z = pos
    node = part(name, (0.2, diameter, diameter), (x, y - 0.1, z), color, material, UPRIGHT, "Cylinder", touch=False)
    node["properties"]["CanQuery"] = False
    return node


def label(text, color, width, height=2.6, offset=3.6):
    """A cartoony BillboardGui label above a pad (same style as the buy buttons)."""
    return {
        "name": "Label",
        "className": "BillboardGui",
        "properties": {
            "Size": {"UDim2": [[width, 0], [height, 0]]},
            "StudsOffset": [0, offset, 0],
            "LightInfluence": 0,
        },
        "children": [
            {
                "name": "Panel",
                "className": "Frame",
                "properties": {
                    "Size": {"UDim2": [[1, 0], [1, 0]]},
                    "BackgroundColor3": [round(c / 255, 3) for c in color],
                    "BorderSizePixel": 0,
                },
                "children": [
                    {"name": "UICorner", "className": "UICorner", "properties": {"CornerRadius": {"UDim": [0.35, 0]}}},
                    {
                        "name": "UIStroke",
                        "className": "UIStroke",
                        "properties": {"Color": OUTLINE, "Thickness": 4, "ApplyStrokeMode": "Border", "LineJoinMode": "Round"},
                    },
                    {
                        "name": "TextLabel",
                        "className": "TextLabel",
                        "properties": {
                            "Text": text,
                            "RichText": True,
                            "Font": "FredokaOne",
                            "TextScaled": True,
                            "TextColor3": [1, 1, 1],
                            "TextStrokeTransparency": 1,
                            "BackgroundTransparency": 1,
                            "AnchorPoint": [0.5, 0.5],
                            "Position": {"UDim2": [[0.5, 0], [0.5, 0]]},
                            "Size": {"UDim2": [[0.88, 0], [0.8, 0]]},
                        },
                        "children": [
                            {
                                "name": "UIStroke",
                                "className": "UIStroke",
                                "properties": {
                                    "Color": OUTLINE,
                                    "Thickness": 2.5,
                                    "ApplyStrokeMode": "Contextual",
                                    "LineJoinMode": "Round",
                                },
                            }
                        ],
                    },
                ],
            }
        ],
    }


def security_pad():
    size = (0.4, PAD_DIAMETER, PAD_DIAMETER)
    children = [ring("SecurityPadRing", PAD_POS, PAD_DIAMETER + 1.5, PAD_RING, "DiamondPlate")]
    return part("SecurityPad", size, PAD_POS, GREEN, "Neon", UPRIGHT, "Cylinder", children=children)


def security_bars():
    """The gate in its DOWN position (RISE studs below where it closes the doorway)."""
    down = -RISE
    bar_length = BARS_TOP - FLOOR
    children = []
    first = -(BAR_COUNT - 1) / 2 * BAR_SPACING
    for i in range(BAR_COUNT):
        x = first + i * BAR_SPACING
        children.append(
            part(
                f"Bar{i + 1}",
                (bar_length, BAR_DIAMETER, BAR_DIAMETER),
                (x, FLOOR + bar_length / 2 + down, DOOR_Z),
                BAR_RED,
                "Metal",
                UPRIGHT,
                "Cylinder",
                touch=False,
            )
        )
    rail_width = FRAME_INNER * 2
    for name, y in (
        ("RailBottom", FLOOR + RAIL_HEIGHT / 2),
        ("RailMiddle", (FLOOR + BARS_TOP) / 2),
        ("RailTop", BARS_TOP - RAIL_HEIGHT / 2),
    ):
        children.append(
            part(name, (rail_width, RAIL_HEIGHT, RAIL_DEPTH), (0, y + down, DOOR_Z), RAIL_RED, "DiamondPlate", touch=False)
        )
    return {
        "name": "SecurityBars",
        "className": "Model",
        "attributes": {"RiseStuds": r(RISE)},
        "children": children,
    }


def trophy_stash():
    size = (0.4, STASH_DIAMETER, STASH_DIAMETER)
    children = [
        ring("TrophyStashRing", STASH_POS, STASH_DIAMETER + 1.5, PURPLE),
        label("STASH STOLEN TROPHIES HERE", PURPLE, 10),
    ]
    return part("TrophyStash", size, STASH_POS, GOLD, "SmoothPlastic", UPRIGHT, "Cylinder", children=children)


def main():
    with open(PLOT_FILE, encoding="utf-8") as f:
        plot = json.load(f)

    children = plot["children"]
    for model in (security_pad(), security_bars(), trophy_stash()):
        index = next((i for i, c in enumerate(children) if c["name"] == model["name"]), None)
        if index is None:
            children.append(model)
        else:
            children[index] = model
        print(f"Wrote {model['name']}")
    with open(PLOT_FILE, "w", encoding="utf-8") as f:
        f.write(json.dumps(plot, indent=2, ensure_ascii=False) + "\n")
    print(f"Updated {os.path.relpath(PLOT_FILE, ROOT)}")


if __name__ == "__main__":
    main()
