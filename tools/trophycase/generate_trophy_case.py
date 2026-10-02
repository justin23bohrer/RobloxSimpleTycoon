#!/usr/bin/env python3
"""Builds the big Trophy Case (the house's first-floor centerpiece) in Plot1.

Run from the repo root:   python3 tools/trophycase/generate_trophy_case.py
Then run:                 python3 tools/plots/generate_plots.py

A tall wooden display cabinet against the middle of the back wall (in front
of the middle back window), 24.8 wide x 14.6 tall x 5.15 deep, showing
exactly 5 trophies in one row on a raised velvet stage, with each trophy's
name on a plaque in the base below it:

  CaseBase        dark wood cabinet base; its front holds the 5 nameplates
  CaseSide*/Back  dark wood sides, red velvet back
  CaseStage       red velvet stage the trophies stand on (gold front lip)
  Riser1-5        velvet steps under each slot, highest in the middle (a
                  podium: slot 1 > slots 2/3 > slots 4/5), gold-topped
  CaseTop         the top board, with the header sign standing on it
  CaseGlass       the glass front (one tall pane)
  Gold*           gold trim: base, stage lip, side edges, valance, top
  CaseSign        "MY CALEB TROPHIES" sign (cartoony, like the owner sign)
  TrophySlot1-5   invisible pads the trophies stand on (Config.TrophyCaseSlots)
                  facing into the room, from the middle outward (1 middle,
                  2 left, 3 right, 4 far left, 5 far right, as seen from the
                  room)
  Nameplate1-5    dark plaques with a gold frame (NameplateFrameN) on the
                  base's front, right below slot N. Each has a SurfaceGui
                  "NameplateGui" with TextLabels "TrophyName" and "PowerText";
                  saved showing a dim "EMPTY". TrophyCaseDisplay fills them.
  CaseLight       a warm SurfaceLight under the top board. It starts
                  Enabled = false: PlotVisibility does not hide lights, so
                  TrophyCaseDisplay turns it on in Show and off in Clear.

It is the existing `TrophyCase` build (Config.Builds, After = "Walls",
BuildButton4); this script does not touch the button. Only the `TrophyCase`
model is rewritten (in place); the rest of the plot file is left exactly as
it is. Edit the numbers here and re-run instead of hand-editing the JSON.

Coordinates are Plot1's (world) coordinates. The first floor's top is at
y = 2, the second floor slab starts at y = 17. The back wall's inside face is
z = -75 (its window glass sticks out to z = -74.75), the room is toward +Z.
"""

import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PLOT_FILE = os.path.join(ROOT, "src", "Workspace", "Map", "Plots", "Plot1.model.json")

NAME = "TrophyCase"
SLOTS = 5  # keep equal to Config.TrophyCaseSlots

FLOOR = 2.0
CX = 0.0  # centered on the back wall (and its middle window)
HALF = 12.0  # outer half width of the cabinet body
SIDE = 0.8  # side thickness
BACK = -74.7  # back of the cabinet (just in front of the window glass)
FRONT = -70.1  # front of the sides and base
VELVET = 0.4  # back panel thickness
BASE_TOP = FLOOR + 3.6  # tall base: room for the nameplates on its front
STAGE_TOP = BASE_TOP + 0.6  # the velvet stage the trophies stand on
TOP_BOTTOM = 14.2  # inside is 8.6 tall: Config.TrophyCaseScale 1.6 + risers fit
TOP_TOP = TOP_BOTTOM + 0.6
SIGN_HEIGHT = 1.8  # sign top = TOP_TOP + 1.8 = 16.6 (< 17, the 2nd floor)
GLASS_Z = FRONT - 0.15  # center of the 0.2 thick glass
SLOT_Z = -72.4
SLOT_SIZE = (3.6, 0.2, 3.4)
SLOT_SPACING = 4.48
SLOT_ORDER = [0, -1, 1, -2, 2]  # slot k -> x offset in spacings (room view: -X is left)
RISER_HEIGHTS = [0.9, 0.5, 0.5, 0.15, 0.15]  # per slot, on top of the stage
RISER_SIZE = (3.8, 3.4)  # x, z
PLATE_SIZE = (4.0, 2.3)  # x, y of each nameplate (0.12 thick)
PLATE_Y = FLOOR + 0.25 + PLATE_SIZE[1] / 2  # center; the frame clears the floor and GoldBase
PLATE_FRAME = 0.1  # gold frame showing around each nameplate
PLATE_MAX_DISTANCE = 60

IDENTITY = [[1, 0, 0], [0, 1, 0], [0, 0, 1]]
FACE_ROOM = [[-1, 0, 0], [0, 1, 0], [0, 0, -1]]  # LookVector +Z (into the room)

WOOD = (92, 60, 38)
DARK_WOOD = (66, 42, 28)
VELVET_RED = (120, 30, 40)
GOLD = (255, 200, 40)
GLASS = (210, 235, 255)
WARM = (255, 214, 160)
OUTLINE = [0.157, 0.11, 0.078]
PLATE_DARK = (40, 28, 20)
EMPTY_TEXT = [0.75, 0.68, 0.6]  # dim "EMPTY" (TrophyCaseDisplay uses the same look)


def r(x):
    x = round(x, 3)
    return int(x) if x == int(x) else x


def part(name, size, pos, color, material="SmoothPlastic", collide=True, transparency=0, rot=None, children=None):
    props = {
        "Size": [r(s) for s in size],
        "CFrame": {"CFrame": {"position": [r(c) for c in pos], "orientation": rot or IDENTITY}},
        "Color": {"Color3uint8": list(color)},
        "Anchored": True,
        "CanTouch": False,
        "Material": material,
        "TopSurface": "Smooth",
        "BottomSurface": "Smooth",
    }
    if not collide:
        props["CanCollide"] = False
        props["CanQuery"] = False
    if transparency:
        props["Transparency"] = transparency
    node = {"name": name, "className": "Part", "properties": props}
    if children:
        node["children"] = children
    return node


def box(name, x0, x1, y0, y1, z0, z1, color, material="SmoothPlastic", **kw):
    """A part filling the box x0..x1, y0..y1, z0..z1."""
    return part(name, (x1 - x0, y1 - y0, z1 - z0), ((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), color, material, **kw)


def warm_light(name, brightness=0.6, light_range=7):
    """A dim, warm SurfaceLight shining down from the bottom face of its part."""
    return {
        "name": name,
        "className": "SurfaceLight",
        "properties": {
            "Face": "Bottom",
            "Color": [WARM[0] / 255, WARM[1] / 255, WARM[2] / 255],
            "Brightness": brightness,
            "Range": light_range,
            "Angle": 120,
            "Shadows": False,
            "Enabled": False,
        },
    }


def sign_gui(text):
    """The cartoony sign style of the owner sign, on the face toward the room."""
    return {
        "name": "SignGui",
        "className": "SurfaceGui",
        "properties": {"Face": "Back", "SizingMode": "PixelsPerStud", "PixelsPerStud": 50, "LightInfluence": 0},
        "children": [
            {
                "name": "Panel",
                "className": "Frame",
                "properties": {
                    "AnchorPoint": [0.5, 0.5],
                    "Position": {"UDim2": [[0.5, 0], [0.5, 0]]},
                    "Size": {"UDim2": [[0.96, 0], [0.84, 0]]},
                    "BackgroundColor3": [0.85, 0.2, 0.25],
                    "BorderSizePixel": 0,
                },
                "children": [
                    {"name": "UICorner", "className": "UICorner", "properties": {"CornerRadius": {"UDim": [0.4, 0]}}},
                    {"name": "UIStroke", "className": "UIStroke",
                     "properties": {"Color": OUTLINE, "Thickness": 8, "ApplyStrokeMode": "Border", "LineJoinMode": "Round"}},
                    {
                        "name": "TextLabel",
                        "className": "TextLabel",
                        "properties": {
                            "Text": text,
                            "Font": "FredokaOne",
                            "TextScaled": True,
                            "TextColor3": [1, 1, 1],
                            "TextStrokeTransparency": 1,
                            "BackgroundTransparency": 1,
                            "AnchorPoint": [0.5, 0.5],
                            "Position": {"UDim2": [[0.5, 0], [0.5, 0]]},
                            "Size": {"UDim2": [[0.9, 0], [0.72, 0]]},
                        },
                        "children": [
                            {"name": "UIStroke", "className": "UIStroke",
                             "properties": {"Color": OUTLINE, "Thickness": 5, "ApplyStrokeMode": "Contextual", "LineJoinMode": "Round"}}
                        ],
                    },
                ],
            }
        ],
    }


def text_label(name, text, y, height, color, transparency=0, wrapped=False):
    props = {
        "Text": text,
        "Font": "FredokaOne",
        "TextScaled": True,
        "TextColor3": color,
        "TextTransparency": transparency,
        "TextStrokeColor3": OUTLINE,
        "TextStrokeTransparency": 1,
        "BackgroundTransparency": 1,
        "AnchorPoint": [0.5, 0],
        "Position": {"UDim2": [[0.5, 0], [y, 0]]},
        "Size": {"UDim2": [[0.9, 0], [height, 0]]},
    }
    if wrapped:
        props["TextWrapped"] = True
    return {"name": name, "className": "TextLabel", "properties": props}


def nameplate_gui():
    """The nameplate's text, on the face toward the room, saved showing the
    empty look. TrophyCaseDisplay sets the text, color, and layout."""
    return {
        "name": "NameplateGui",
        "className": "SurfaceGui",
        "properties": {
            "Face": "Back",
            "SizingMode": "PixelsPerStud",
            "PixelsPerStud": 100,
            "LightInfluence": 0,
            "MaxDistance": PLATE_MAX_DISTANCE,
        },
        "children": [
            text_label("TrophyName", "EMPTY", 0.3, 0.4, EMPTY_TEXT, transparency=0.4, wrapped=True),
            text_label("PowerText", "", 0.6, 0.32, [1, 1, 1], wrapped=True),
        ],
    }


def trophy_case():
    x0, x1 = CX - HALF, CX + HALF
    ix0, ix1 = x0 + SIDE, x1 - SIDE  # inside faces of the sides
    inner_back = BACK + VELVET
    stage_front = GLASS_Z - 0.1
    parts = [
        box("CaseBase", x0, x1, FLOOR, BASE_TOP, BACK, FRONT, WOOD, "Wood"),
        box("CaseSideLeft", x0, ix0, BASE_TOP, TOP_BOTTOM, BACK, FRONT, WOOD, "Wood"),
        box("CaseSideRight", ix1, x1, BASE_TOP, TOP_BOTTOM, BACK, FRONT, WOOD, "Wood"),
        box("CaseBack", ix0, ix1, BASE_TOP, TOP_BOTTOM, BACK, inner_back, VELVET_RED, "Fabric"),
        box("CaseStage", ix0, ix1, BASE_TOP, STAGE_TOP, inner_back, stage_front, VELVET_RED, "Fabric"),
        box("CaseTop", x0 - 0.4, x1 + 0.4, TOP_BOTTOM, TOP_TOP, BACK, FRONT + 0.4, WOOD, "Wood",
            children=[warm_light("CaseLight", brightness=0.7, light_range=10)]),
        # Glass front, one tall pane.
        box("CaseGlass", ix0, ix1, BASE_TOP, TOP_BOTTOM, GLASS_Z - 0.1, GLASS_Z + 0.1,
            GLASS, "Glass", transparency=0.65),
        # Gold trim (plain gold, not Neon: no glare).
        box("GoldBase", x0, x1, BASE_TOP - 0.35, BASE_TOP, FRONT, FRONT + 0.15, GOLD, collide=False),
        box("GoldStageLip", ix0, ix1, STAGE_TOP - 0.12, STAGE_TOP, stage_front - 0.12, stage_front, GOLD,
            collide=False),
        box("GoldValance", ix0, ix1, TOP_BOTTOM - 0.35, TOP_BOTTOM, stage_front - 0.12, stage_front, GOLD,
            collide=False),
        box("GoldEdgeLeft", x0, ix0, BASE_TOP, TOP_BOTTOM, FRONT, FRONT + 0.15, GOLD, collide=False),
        box("GoldEdgeRight", ix1, x1, BASE_TOP, TOP_BOTTOM, FRONT, FRONT + 0.15, GOLD, collide=False),
        box("GoldTop", x0 - 0.4, x1 + 0.4, TOP_TOP - 0.4, TOP_TOP - 0.15, FRONT + 0.4, FRONT + 0.55, GOLD, collide=False),
        # Header sign standing on the top board, near its front.
        box("CaseSign", CX - 9, CX + 9, TOP_TOP, TOP_TOP + SIGN_HEIGHT, FRONT - 0.6, FRONT - 0.2, GOLD,
            collide=False, children=[sign_gui("MY CALEB TROPHIES")]),
    ]
    rx, rz = RISER_SIZE[0] / 2, RISER_SIZE[1] / 2
    pw, ph = PLATE_SIZE[0] / 2, PLATE_SIZE[1] / 2
    for i in range(SLOTS):
        x = CX + SLOT_ORDER[i] * SLOT_SPACING
        top = STAGE_TOP + RISER_HEIGHTS[i]
        # A velvet step under the slot with a gold top edge (the podium).
        parts.append(box(f"Riser{i + 1}", x - rx, x + rx, STAGE_TOP, top - 0.1, SLOT_Z - rz, SLOT_Z + rz,
                         VELVET_RED, "Fabric"))
        parts.append(box(f"RiserTrim{i + 1}", x - rx, x + rx, top - 0.1, top, SLOT_Z - rz, SLOT_Z + rz, GOLD))
        # The slot pad's top is the riser's top (the trophy stands on it).
        parts.append(part(f"TrophySlot{i + 1}", SLOT_SIZE, (x, top - SLOT_SIZE[1] / 2, SLOT_Z), GOLD,
                          collide=False, transparency=1, rot=FACE_ROOM))
        # Its nameplate on the base's front, right below it.
        parts.append(box(f"NameplateFrame{i + 1}", x - pw - PLATE_FRAME, x + pw + PLATE_FRAME,
                         PLATE_Y - ph - PLATE_FRAME, PLATE_Y + ph + PLATE_FRAME, FRONT, FRONT + 0.08, GOLD,
                         collide=False))
        parts.append(box(f"Nameplate{i + 1}", x - pw, x + pw, PLATE_Y - ph, PLATE_Y + ph, FRONT + 0.08,
                         FRONT + 0.2, PLATE_DARK, collide=False, children=[nameplate_gui()]))
    return {"name": NAME, "className": "Model", "children": parts}


def main():
    with open(PLOT_FILE, encoding="utf-8") as f:
        plot = json.load(f)

    model = trophy_case()
    children = plot["children"]
    index = next((i for i, c in enumerate(children) if c["name"] == NAME), None)
    if index is None:
        children.append(model)
    else:
        children[index] = model
    with open(PLOT_FILE, "w", encoding="utf-8") as f:
        f.write(json.dumps(plot, indent=2, ensure_ascii=False) + "\n")
    print(f"Wrote {NAME} ({len(model['children'])} parts) to {os.path.relpath(PLOT_FILE, ROOT)}")


if __name__ == "__main__":
    main()
