#!/usr/bin/env python3
"""Adds the garage, the car parked in it, and its trophy pad to Plot1.

Run from the repo root:   python3 tools/garage/generate_garage.py
Then run:                 python3 tools/plots/generate_plots.py

An attached one-car garage on the house's right side (+X on Plot1, the
stairs side), outside the 66 x 66 base, that matches the house: off-white
brick, gray trim, gray shingle gable roof. Its rolled-up door faces the
statue side (+Z). Inside: a concrete floor, two ceiling lights, a workbench
with a pegboard of tools, a storage rack, and a wall charger plugged into a
white VW ID.4 (id4_car.py) parked nose out.

  Garage         walls, roof, floor, door, lights, workbench, rack,
                 charger, driveway ramp
  GarageCar      the white ID.4 (decoration only)
  TrophyButton1  the gold garage pad on the grass in front of the driveway
                 (same structure as BuildButton1)

Garage and GarageCar are drawn as normal visible parts; the game hides them
until the garage is bought (Config.TrophyBuilds, PlotVisibility). The
ceiling lights (SurfaceLights named GarageLight) start disabled, because
PlotVisibility does not turn lights off; the game switches them on with the
garage.

Only the three instances above are rewritten (in place if they exist,
otherwise added at the end); every other child of the plot is left exactly
as it is, so this is safe to run before or after the house, furniture, and
backyard generators, and running it again changes nothing. All parts are
Anchored; walls, floor, roof, and the big furniture blocks are solid, small
details are looks only.

Garage on Plot1 (world coordinates): x 33.3..58.6 (house wall at x 33),
z -38.3..-8.8 (roof overhang), floor top y 2 like Base, walls up to y 17,
ridge at y 23. Driveway ramp to z -6.5, pad at (45.8, 1.2, -2.5).
"""

import json
import os
import sys

sys.dont_write_bytecode = True  # no __pycache__ next to the tool
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import id4_car  # noqa: E402
from parts import ALONG_Z, Parts, TURN_180, UPRIGHT, r  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PLOT_FILE = os.path.join(ROOT, "src", "Workspace", "Map", "Plots", "Plot1.model.json")

# Colors and materials (the house's, see tools/house/generate_house.py).
BRICK = (238, 235, 228)
BRICK_MATERIAL = "Brick"
TRIM = (122, 126, 130)
GLASS = (44, 50, 58)
ROOF = (96, 100, 104)
ROOF_MATERIAL = "Slate"
RIDGE = (78, 82, 86)
CONCRETE = (178, 178, 172)
CEILING = (228, 228, 224)
DOOR_WHITE = (242, 242, 238)
WOOD = (160, 112, 66)
PEGBOARD = (190, 150, 100)
METAL = (150, 156, 162)
DARK = (40, 40, 46)
WARM = (255, 236, 200)

# Layout (Plot1). The house's right wall face is at x 33; its trim sticks
# out to x 33.3, so the garage starts there and uses the house wall as its
# left wall.
GX0, GX1 = 33.3, 58.3  # garage left edge, right wall outer face
CX = (GX0 + GX1) / 2  # 45.8: middle of the door, the ridge and the car
ZF, ZB = -10, -38  # front face (flush with the house front), back face
FLOOR = 2  # top of the garage floor = top of Base
WALL_TOP = 17  # = the house's first floor
DOOR_HALF, DOOR_TOP = 8, 13  # door opening x 37.8..53.8, up to y 13
RISE = 6  # eaves (y 17) to ridge (y 23)
OVERHANG = 1.2
ROOF_T = 0.6
CAR_Z = -23.5  # middle of the car (nose at z -16, tail at z -31)
PAD = (CX, -2.5)  # TrophyButton1 on the grass (top of Ground is y 1)
GROUND_TOP = 1

# Wedges turned so their slope faces -X / +X (length along Z), as in the house.
SLOPE_LEFT = [[0, 0, 1], [0, 1, 0], [-1, 0, 0]]
SLOPE_RIGHT = [[0, 0, -1], [0, 1, 0], [1, 0, 0]]
PAD_ROT = [[0, -1, 0], [1, 0, 0], [0, 0, 1]]
OUTLINE = [0.157, 0.11, 0.078]


def shell(g):
    """Floor, brick walls, gray trim, the door opening and the rolled-up door."""
    dl, dr = CX - DOOR_HALF, CX + DOOR_HALF
    g.box("Floor", (33, GROUND_TOP, ZB), (GX1, FLOOR, ZF), CONCRETE, "Concrete", collide=True)
    # Ramp from the grass up to the garage floor, in front of the door.
    g.wedge("Driveway", (2 * DOOR_HALF + 1, FLOOR - GROUND_TOP, 3.5), (CX, (GROUND_TOP + FLOOR) / 2, ZF + 1.75),
            CONCRETE, "Concrete", rot=TURN_180, collide=True)

    brick = lambda name, lo, hi: g.box(name, lo, hi, BRICK, BRICK_MATERIAL, collide=True)
    brick("WallRight", (GX1 - 1, FLOOR, ZB), (GX1, WALL_TOP, ZF))
    brick("WallBack", (GX0, FLOOR, ZB), (GX1 - 1, WALL_TOP, ZB + 1))
    # Fills the gap between the house wall and the back wall (between the
    # house's plinth and floor band, which already reach x 33.3).
    brick("WallBackFiller", (33, FLOOR + 0.8, ZB), (GX0, WALL_TOP - 1, ZB + 1))
    brick("WallFrontLeft", (GX0, FLOOR, ZF - 1), (dl, WALL_TOP, ZF))
    brick("WallFrontRight", (dr, FLOOR, ZF - 1), (GX1 - 1, WALL_TOP, ZF))
    brick("DoorHeader", (dl, DOOR_TOP, ZF - 1), (dr, WALL_TOP, ZF))
    g.box("Ceiling", (GX0, WALL_TOP - 0.4, ZB + 1), (GX1 - 1, WALL_TOP, ZF - 1), CEILING, collide=True)

    trim = lambda name, lo, hi: g.box(name, lo, hi, TRIM)
    trim("DoorFrameLeft", (dl, FLOOR, ZF - 1.2), (dl + 0.6, DOOR_TOP, ZF + 0.2))
    trim("DoorFrameRight", (dr - 0.6, FLOOR, ZF - 1.2), (dr, DOOR_TOP, ZF + 0.2))
    trim("DoorFrameTop", (dl, DOOR_TOP - 0.6, ZF - 1.2), (dr, DOOR_TOP, ZF + 0.2))
    for name, x0 in (("CornerFrontRight", GX1 - 1.3), ("CornerBackRight", GX1 - 1.3), ("CornerBackLeft", GX0)):
        z0 = ZF - 1.3 if "Front" in name else ZB - 0.3
        trim(name, (x0, FLOOR, z0), (x0 + 1.6, WALL_TOP, z0 + 1.6))
    for prefix, y0, y1 in (("Plinth", FLOOR, FLOOR + 0.8), ("FloorBand", WALL_TOP - 1, WALL_TOP)):
        trim(f"{prefix}Right", (GX1, y0, ZB), (GX1 + 0.3, y1, ZF))
        trim(f"{prefix}Back", (GX0, y0, ZB - 0.3), (GX1 + 0.3, y1, ZB))
        if prefix == "Plinth":
            trim("PlinthFrontLeft", (GX0, y0, ZF), (dl, y1, ZF + 0.3))
            trim("PlinthFrontRight", (dr, y0, ZF), (GX1 + 0.3, y1, ZF + 0.3))
        else:
            trim("FloorBandFront", (GX0, y0, ZF), (GX1 + 0.3, y1, ZF + 0.3))

    # Rolled-up door: the roll box above the opening inside, the door's
    # bottom edge peeking out under the frame, and the side tracks.
    g.box("DoorRollBox", (dl - 0.2, DOOR_TOP + 1, ZF - 2.8), (dr + 0.2, WALL_TOP - 0.6, ZF - 1), TRIM)
    g.box("DoorBottomEdge", (dl + 0.2, DOOR_TOP - 1, ZF - 1.5), (dr - 0.2, DOOR_TOP - 0.4, ZF - 1.25), DOOR_WHITE)
    g.box("DoorSeal", (dl + 0.2, DOOR_TOP - 1.1, ZF - 1.5), (dr - 0.2, DOOR_TOP - 1, ZF - 1.25), DARK)
    for name, x in (("DoorTrackLeft", dl + 0.2), ("DoorTrackRight", dr - 0.6)):
        g.box(name, (x, FLOOR, ZF - 1.9), (x + 0.4, DOOR_TOP + 1, ZF - 1.3), METAL, "Metal")

    # Lanterns on both sides of the door.
    for name, x in (("LanternLeft", (GX0 + dl) / 2), ("LanternRight", (dr + GX1 - 1.3) / 2)):
        g.box(f"{name}Plate", (x - 0.4, 8.6, ZF), (x + 0.4, 10.6, ZF + 0.15), DARK)
        g.box(f"{name}Glass", (x - 0.3, 8.9, ZF + 0.15), (x + 0.3, 10.1, ZF + 0.7), WARM, "Neon")
        g.box(f"{name}Cap", (x - 0.45, 10.1, ZF + 0.1), (x + 0.45, 10.4, ZF + 0.8), DARK)


def right_window(g, name, z, y, w=4, h=6):
    """A house-style window in the right wall (outside and inside views)."""
    x = GX1
    g.box(f"{name}Frame", (x, y - h / 2 - 0.4, z - w / 2 - 0.4), (x + 0.3, y + h / 2 + 0.4, z + w / 2 + 0.4), TRIM)
    g.box(f"{name}Glass", (x + 0.1, y - h / 2, z - w / 2), (x + 0.4, y + h / 2, z + w / 2), GLASS)
    g.box(f"{name}GrilleV", (x + 0.4, y - h / 2, z - 0.125), (x + 0.5, y + h / 2, z + 0.125), TRIM)
    g.box(f"{name}GrilleH", (x + 0.4, y - 0.125, z - w / 2), (x + 0.5, y + 0.125, z + w / 2), TRIM)
    g.box(f"{name}Sill", (x, y - h / 2 - 0.6, z - w / 2 - 0.6), (x + 0.7, y - h / 2 - 0.2, z + w / 2 + 0.6), TRIM)
    g.box(f"{name}InsideFrame", (x - 1.2, y - h / 2 - 0.4, z - w / 2 - 0.4), (x - 1, y + h / 2 + 0.4, z + w / 2 + 0.4), TRIM)
    g.box(f"{name}InsideGlass", (x - 1.25, y - h / 2, z - w / 2), (x - 1.05, y + h / 2, z + w / 2), GLASS)


def roof(g):
    """Gable roof, ridge along Z: brick triangles over the front and back
    walls, gray slate slopes, rake boards, ridge cap, fascia, and flashing
    where it meets the house."""
    peak = WALL_TOP + RISE
    pitch = RISE / (CX - GX0)
    eave_x, eave_y = GX1 + OVERHANG, WALL_TOP - OVERHANG * pitch
    zf, zb = ZF + OVERHANG, ZB - OVERHANG
    zm, depth = (zf + zb) / 2, zf - zb
    g.slab("RoofLeft", (GX0, WALL_TOP, zm), (CX, peak, zm), depth, ROOF_T, ROOF, ROOF_MATERIAL, collide=True)
    g.slab("RoofRight", (CX, peak, zm), (eave_x, eave_y, zm), depth, ROOF_T, ROOF, ROOF_MATERIAL, collide=True)
    half = CX - GX0
    for end, z in (("Front", ZF - 0.5), ("Back", ZB + 0.5)):
        g.wedge(f"Gable{end}Left", (1, RISE, half), (GX0 + half / 2, WALL_TOP + RISE / 2, z), BRICK, BRICK_MATERIAL,
                rot=SLOPE_LEFT, collide=True)
        g.wedge(f"Gable{end}Right", (1, RISE, half), (CX + half / 2, WALL_TOP + RISE / 2, z), BRICK, BRICK_MATERIAL,
                rot=SLOPE_RIGHT, collide=True)
    lift = ROOF_T / 2
    for end, z in (("Front", zf + 0.15), ("Back", zb - 0.15)):
        # Starts a little in from the house so it clears the house's floor band.
        g.beam(f"Rake{end}Left", (GX0 + 0.5, WALL_TOP + lift + 0.5 * pitch, z), (CX, peak + lift, z), 0.3, 0.9, TRIM)
        g.beam(f"Rake{end}Right", (CX, peak + lift, z), (eave_x, eave_y + lift, z), 0.3, 0.9, TRIM)
    g.beam("RidgeCap", (CX, peak + ROOF_T, zf), (CX, peak + ROOF_T, zb), 0.9, 0.9, RIDGE)
    g.box("FasciaRight", (eave_x, eave_y - 0.5, zb), (eave_x + 0.3, eave_y + 0.4, zf), TRIM)
    g.box("SoffitRight", (GX1 + 0.3, eave_y - 0.4, zb), (eave_x, eave_y - 0.15, zf), CEILING)
    g.box("Flashing", (33, WALL_TOP, zb), (GX0 + 0.3, WALL_TOP + 0.9, zf), TRIM)
    # Round vent in the front gable, like the house's.
    vent_y = WALL_TOP + RISE * 0.4
    g.cyl("GableVent", 0.3, 2.2, (CX, vent_y, ZF + 0.15), TRIM, rot=ALONG_Z)
    g.cyl("GableVentHole", 0.3, 1.7, (CX, vent_y, ZF + 0.25), GLASS, rot=ALONG_Z)


def ceiling_light(g, name, z):
    """A tube light under the ceiling; its SurfaceLight starts disabled."""
    y = WALL_TOP - 0.4
    g.box(f"{name}Housing", (CX - 0.7, y - 0.3, z - 3.6), (CX + 0.7, y, z + 3.6), METAL)
    light = {
        "name": "GarageLight",
        "className": "SurfaceLight",
        "properties": {
            "Face": "Bottom",
            "Color": [WARM[0] / 255, WARM[1] / 255, WARM[2] / 255],
            "Brightness": 1.5,
            "Range": 18,
            "Angle": 120,
            "Shadows": False,
            "Enabled": False,
        },
    }
    g.box(f"{name}Tube", (CX - 0.35, y - 0.55, z - 3.3), (CX + 0.35, y - 0.3, z + 3.3), WARM, "Neon",
          children=[light])


def workbench(g):
    """Wooden bench against the back wall (behind the car's left side),
    a pegboard with tools, a red toolbox, and a vise."""
    x0, x1 = 47.5, 56.5
    back = ZB + 1  # inside face of the back wall
    front = back + 2.6
    top = FLOOR + 3.6
    g.box("BenchTop", (x0, top - 0.4, back), (x1, top, front), WOOD, "Wood", collide=True)
    g.box("BenchShelf", (x0 + 0.2, FLOOR + 1, back + 0.1), (x1 - 0.2, FLOOR + 1.2, front - 0.2), WOOD, "Wood")
    for i, (x, z) in enumerate(((x0 + 0.2, back + 0.2), (x1 - 0.2, back + 0.2), (x0 + 0.2, front - 0.2), (x1 - 0.2, front - 0.2)), 1):
        g.box(f"BenchLeg{i}", (x - 0.2, FLOOR, z - 0.2), (x + 0.2, top - 0.4, z + 0.2), WOOD, "Wood", collide=True)
    g.box("Pegboard", (x0 + 0.5, top + 1.2, back), (x1 - 0.5, top + 5.6, back + 0.15), PEGBOARD, "Wood")
    z = back + 0.25
    g.box("HammerHandle", (49.3, top + 2.2, z - 0.1), (49.55, top + 4.2, z + 0.1), WOOD, "Wood")
    g.box("HammerHead", (48.95, top + 4.2, z - 0.15), (49.95, top + 4.6, z + 0.15), METAL, "Metal")
    g.box("Wrench", (50.9, top + 2.0, z - 0.06), (51.15, top + 4.2, z + 0.06), METAL, "Metal")
    g.cyl("WrenchHead", 0.12, 0.7, (51.03, top + 4.4, z), METAL, "Metal", rot=ALONG_Z)
    for i, (x, color) in enumerate(((52.5, (220, 50, 50)), (53.3, (250, 200, 40))), 1):
        g.box(f"Screwdriver{i}Handle", (x - 0.15, top + 3.4, z - 0.15), (x + 0.15, top + 4.4, z + 0.15), color)
        g.box(f"Screwdriver{i}Shaft", (x - 0.05, top + 2.4, z - 0.05), (x + 0.05, top + 3.4, z + 0.05), METAL, "Metal")
    g.box("Toolbox", (53.4, top, back + 0.5), (55.8, top + 1.2, back + 1.7), (210, 40, 40), collide=True)
    g.box("ToolboxHandle", (54.2, top + 1.2, back + 1.0), (55.0, top + 1.45, back + 1.2), DARK)
    g.box("ViseBase", (48.2, top, front - 1.0), (49.4, top + 0.5, front - 0.1), (60, 90, 160))
    g.box("ViseJaw", (48.4, top + 0.5, front - 0.6), (49.2, top + 1.1, front - 0.2), (60, 90, 160))
    g.cyl("TapeMeasure", 0.4, 0.7, (51.2, top + 0.2, front - 0.9), (250, 210, 40), rot=UPRIGHT)


def storage_rack(g):
    """A metal rack in the back-left corner with bins, boxes, and paint cans."""
    x0, x1 = 34.5, 41.5
    back = ZB + 1
    front = back + 2
    for i, (x, z) in enumerate(((x0, back), (x1 - 0.3, back), (x0, front - 0.3), (x1 - 0.3, front - 0.3)), 1):
        g.box(f"RackPost{i}", (x, FLOOR, z), (x + 0.3, FLOOR + 8.2, z + 0.3), METAL, "Metal", collide=True)
    for i, y in enumerate((FLOOR + 0.4, FLOOR + 2.9, FLOOR + 5.4, FLOOR + 7.9), 1):
        g.box(f"RackShelf{i}", (x0, y, back), (x1, y + 0.2, front), METAL, "Metal", collide=True)
    items = [
        ("BinBlue", (34.8, FLOOR + 0.6), (37.6, FLOOR + 2.4), (60, 120, 220)),
        ("BinRed", (38.2, FLOOR + 0.6), (41.1, FLOOR + 2.2), (220, 70, 60)),
        ("BoxTan", (34.9, FLOOR + 3.1), (37.8, FLOOR + 5.0), (196, 160, 110)),
        ("BinGreen", (35.0, FLOOR + 5.6), (38.0, FLOOR + 7.2), (70, 170, 90)),
        ("BoxTanSmall", (38.6, FLOOR + 5.6), (40.8, FLOOR + 6.9), (196, 160, 110)),
    ]
    for name, (xa, ya), (xb, yb), color in items:
        g.box(name, (xa, ya, back + 0.2), (xb, yb, front - 0.2), color)
    for i, (x, band) in enumerate(((38.8, (90, 140, 230)), (40.3, (240, 120, 40))), 1):
        y = FLOOR + 3.1
        g.cyl(f"PaintCan{i}", 1.4, 1.1, (x, y + 0.7, back + 1), (235, 235, 235), "Metal", rot=UPRIGHT)
        g.cyl(f"PaintCan{i}Label", 0.6, 1.14, (x, y + 0.7, back + 1), band, rot=UPRIGHT)


def charger(g):
    """An EV wall charger on the house wall, its cable running along the
    floor to the charge port on the car's right rear (-X side)."""
    z = CAR_Z - 5.5  # the car's charge port
    g.box("ChargerBox", (33, 5, z - 0.7), (33.55, 7.4, z + 0.7), (245, 245, 245), collide=True)
    g.box("ChargerFace", (33.55, 5.3, z - 0.5), (33.62, 7.1, z + 0.5), DARK)
    g.box("ChargerLight", (33.6, 6.6, z - 0.2), (33.66, 6.8, z + 0.2), (60, 230, 120), "Neon")
    port_x = CX - 3.6
    path = [(33.6, 5.1, z), (33.9, FLOOR + 0.12, z + 0.4), (port_x - 0.6, FLOOR + 0.12, z + 0.4),
            (port_x - 0.3, FLOOR + 2.4, z + 0.3), (port_x + 0.05, 5.3, z + 0.15)]
    for i, (a, b) in enumerate(zip(path, path[1:]), 1):
        g.beam(f"ChargerCable{i}", a, b, 0.22, 0.22, DARK)


def garage():
    g = Parts("Garage")
    shell(g)
    right_window(g, "WindowRight1", -17, 9)
    right_window(g, "WindowRight2", -31, 9)
    roof(g)
    ceiling_light(g, "LightFront", -17)
    ceiling_light(g, "LightBack", -30)
    workbench(g)
    storage_rack(g)
    charger(g)
    # Yellow wheel stop behind the rear wheels, and an oil spot under the car.
    g.box("WheelStop", (CX - 3, FLOOR, CAR_Z - 7.2), (CX + 3, FLOOR + 0.45, CAR_Z - 6.5), (250, 200, 40), collide=True)
    g.cyl("OilStain", 0.04, 3, (CX + 0.8, FLOOR + 0.02, CAR_Z + 1), (120, 120, 116), rot=UPRIGHT)
    return g.model()


def trophy_button():
    """TrophyButton1: BuildButton1's pad structure in the trophy colors
    (gold pad, dark purple ring, purple sign), resting on the grass."""
    x, z = PAD
    y = GROUND_TOP
    label = {
        "name": "Label",
        "className": "BillboardGui",
        "properties": {"Size": {"UDim2": [[7, 0], [2.8, 0]]}, "StudsOffset": [0, 3.6, 0], "LightInfluence": 0},
        "children": [{
            "name": "Panel",
            "className": "Frame",
            "properties": {"Size": {"UDim2": [[1, 0], [1, 0]]}, "BackgroundColor3": [150 / 255, 70 / 255, 230 / 255],
                           "BorderSizePixel": 0},
            "children": [
                {"name": "UICorner", "className": "UICorner", "properties": {"CornerRadius": {"UDim": [0.35, 0]}}},
                {"name": "UIStroke", "className": "UIStroke",
                 "properties": {"Color": OUTLINE, "Thickness": 4, "ApplyStrokeMode": "Border", "LineJoinMode": "Round"}},
                {
                    "name": "TextLabel",
                    "className": "TextLabel",
                    "properties": {
                        "Text": "Garage",  # the game sets the real label
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
                    "children": [{"name": "UIStroke", "className": "UIStroke",
                                  "properties": {"Color": OUTLINE, "Thickness": 2.5, "ApplyStrokeMode": "Contextual",
                                                 "LineJoinMode": "Round"}}],
                },
            ],
        }],
    }
    ring = {
        "name": "TrophyButton1Ring",
        "className": "Part",
        "properties": {
            "Shape": "Cylinder",
            "Size": [0.2, 7.5, 7.5],
            "CFrame": {"CFrame": {"position": [r(x), r(y + 0.1), r(z)], "orientation": PAD_ROT}},
            "Color": {"Color3uint8": [110, 40, 170]},
            "Anchored": True,
            "CanTouch": False,
            "CanQuery": False,
            "Material": "SmoothPlastic",
            "TopSurface": "Smooth",
            "BottomSurface": "Smooth",
        },
    }
    return {
        "name": "TrophyButton1",
        "className": "Part",
        "properties": {
            "Size": [0.4, 6, 6],
            "CFrame": {"CFrame": {"position": [r(x), r(y + 0.2), r(z)], "orientation": PAD_ROT}},
            "Color": {"Color3uint8": [255, 200, 40]},
            "Anchored": True,
            "Material": "SmoothPlastic",
            "TopSurface": "Smooth",
            "BottomSurface": "Smooth",
            "Shape": "Cylinder",
        },
        "children": [ring, label],
    }


def count_parts(node):
    own = 1 if node["className"] in ("Part", "WedgePart") else 0
    return own + sum(count_parts(c) for c in node.get("children", []))


def main():
    with open(PLOT_FILE, encoding="utf-8") as f:
        plot = json.load(f)
    new = [garage(), id4_car.build((CX, FLOOR, CAR_Z)), trophy_button()]
    children = plot["children"]
    for node in new:
        spots = [i for i, c in enumerate(children) if c.get("name") == node["name"]]
        if spots:
            children[spots[0]] = node
            for i in reversed(spots[1:]):  # drop stray duplicates
                del children[i]
        else:
            children.append(node)
    with open(PLOT_FILE, "w", encoding="utf-8") as f:
        f.write(json.dumps(plot, indent=2, ensure_ascii=False) + "\n")
    for node in new:
        print(f"{node['name']}: {count_parts(node)} parts")


if __name__ == "__main__":
    main()
