#!/usr/bin/env python3
"""Adds the backyard behind the house (and its trophy pads) to Plot1.

Run from the repo root:   python3 tools/backyard/generate_backyard.py
Then run:                 python3 tools/plots/generate_plots.py

Laid out like the user's sketch, behind the house's back wall (z = -76) out
to z = -121, between the plot's sides (x -33..33). Seen from the back door,
looking out into the yard ("left" is -X):

  Pool           a long walk-in pool on the left (x -30..-8) running front
                 to back: a raised basin (stone walls, sand-colored coping
                 3.6 studs above the grass, light blue floor and lining),
                 see-through water about waist deep that you walk through,
                 steps up to the coping and back out in its front +X corner,
                 a red brick wall along its outer (-X) edge, a diving board
                 at the far end, two beach balls
  BackyardPath   a flagstone path from the back door (x 20) straight back to
                 the hangout, gray rocks and brown dirt patches on both sides
  Hangout        a square stone patio at the end of the path with a fire pit
                 in the middle (ring of stones, logs, Fire + embers + light,
                 saved disabled: the game code turns them on when shown)
                 and 5 cartoony outdoor chairs around it
  BackyardFence  a white picket fence (about 8 studs tall) on the yard's
                 left, right and back sides, meeting the house's back corners
                 (looks only: the game shows it with the Walls build and
                 never keeps anyone out of the yard)
  BackDoor       the door in the house's back wall (the opening itself is cut
                 by tools/house/generate_house.py, BACK_DOOR_* there): the
                 Door panel (its window, panels and knobs are child parts of
                 Door), the DoorSign above it on the inside (a TextLabel and
                 a smaller ProgressLabel, both rewritten by the game), an
                 outside casing, a little awning, and a stone step down to
                 the grass
  TrophyButton2  gold pad by the pool        (builds Pool)
  TrophyButton3  gold pad by the path start  (builds BackyardPath)
  TrophyButton4  gold pad at the patio's front-left corner (builds Hangout)

The pads copy BuildButton1's structure (pad, <Name>Ring, Label billboard with
one TextLabel) in gold with a purple ring and panel. They stand on the grass,
so they can be reached from the back door before anything is built. The game
code decides what is shown when (BackDoor, BackyardFence and the pads appear
with the walls; Pool, BackyardPath and Hangout when built); here they are
plain visible parts.

Only the instances named in MANAGED are rewritten (in place, or appended if
missing), and those named in REMOVED (BackyardZone, the old push-out box) are
deleted; every other child of the plot is left exactly as it is, so this can
be re-run any time. Edit the numbers here and re-run instead of hand-editing
the JSON. Plain parts only (no meshes, decals, or Terrain).

Coordinates are Plot1's (world) coordinates. The ground's top is y = 1, the
house floor (Base) top is y = 2.
"""

import json
import math
import os
import random

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PLOT_FILE = os.path.join(ROOT, "src", "Workspace", "Map", "Plots", "Plot1.model.json")

G = 1.0  # top of the grass (Ground)
FLOOR = 2.0  # top of the plot's Base (the house floor)
HOUSE_BACK = -76.0  # outer face of the house's back wall
YARD_BACK = -121.0  # far side of the backyard (outer face of the back fence)
X_OUT = 33.0  # the plot's sides

# The back door opening (must match tools/house/generate_house.py).
BACK_DOOR_X = 20
BACK_DOOR_HALF = 3
BACK_DOOR_TOP = 12
WALL_INNER = HOUSE_BACK + 1  # inside face of the 1-stud back wall

FENCE_HEIGHT = 8

IDENTITY = [[1, 0, 0], [0, 1, 0], [0, 0, 1]]
PAD_ROT = [[0, -1, 0], [1, 0, 0], [0, 0, 1]]  # a Cylinder with its round face up

# Colors (RGB 0-255). Bright and simple, like the house and the furniture.
TRIM = (122, 126, 130)  # the house's gray trim
WHITE_FENCE = (246, 244, 238)
FENCE_CAP = (226, 224, 218)
RED_BRICK = (178, 64, 50)
WALL_CAP = (214, 206, 192)
COPING = (232, 220, 190)
POOL_FLOOR = (150, 222, 250)
POOL_LANE = (40, 110, 200)
WATER = (40, 165, 235)
BOARD = (240, 248, 255)
BOARD_STAND = (70, 140, 210)
PATH_BASE = (108, 108, 114)
FLAGSTONES = [(178, 178, 184), (192, 188, 180), (164, 166, 172), (186, 182, 176)]
ROCKS = [(128, 128, 134), (150, 150, 156), (116, 116, 122), (140, 136, 130)]
DIRT = [(118, 82, 52), (104, 72, 46), (130, 92, 58)]
PATIO_BORDER = (132, 128, 124)
PATIO_TILES = [(196, 190, 180), (182, 176, 168)]
ASH = (58, 54, 52)
PIT_STONES = [(110, 108, 112), (138, 134, 130), (96, 94, 98)]
LOG = (112, 72, 42)
CHAIR_COLORS = [(232, 84, 72), (74, 152, 232), (250, 200, 60), (92, 192, 112), (164, 104, 224)]
DOOR_WOOD = (156, 92, 52)
DOOR_PANEL = (130, 74, 40)
GLASS = (44, 50, 58)  # same as the house windows
GOLD = (255, 200, 40)
STEP_STONE = (168, 168, 174)

# Pads: (index, build it shows next to, x, z, placeholder label). The game
# code sets the real label text.
PADS = [
    (2, "Pool", -3, -95, "Build Pool"),
    (3, "BackyardPath", 10.5, -85, "Build Path"),
    (4, "Hangout", 5.5, -104, "Build Hangout"),
]
PAD_COLOR = [255, 200, 40]  # gold
RING_COLOR = [110, 40, 170]  # dark purple
PANEL_COLOR = [150 / 255, 70 / 255, 230 / 255]  # purple, like the owner sign
DARK = [0.157, 0.11, 0.078]  # the signs' dark outline color

MANAGED = [
    "Pool", "BackyardPath", "Hangout", "BackyardFence",
    "TrophyButton2", "TrophyButton3", "TrophyButton4", "BackDoor",
]
REMOVED = ["BackyardZone"]  # no longer used by the game (no push-out)


# --- helpers ----------------------------------------------------------------

def r(x):
    x = round(x, 3)
    return int(x) if x == int(x) else x


def rot6(v):
    v = round(v, 6)
    return int(v) if v == int(v) else v


def matmul(a, b):
    return [[sum(a[i][k] * b[k][j] for k in range(3)) for j in range(3)] for i in range(3)]


def rot_x(deg):
    c, s = math.cos(math.radians(deg)), math.sin(math.radians(deg))
    return [[1, 0, 0], [0, c, -s], [0, s, c]]


def rot_y(deg):
    c, s = math.cos(math.radians(deg)), math.sin(math.radians(deg))
    return [[c, 0, s], [0, 1, 0], [-s, 0, c]]


def rot_z(deg):
    c, s = math.cos(math.radians(deg)), math.sin(math.radians(deg))
    return [[c, -s, 0], [s, c, 0], [0, 0, 1]]


def apply(m, v):
    return tuple(sum(m[i][k] * v[k] for k in range(3)) for i in range(3))


UPRIGHT = rot_z(90)  # a Cylinder's axis (X) pointing up


def part(name, size, pos, color, material="SmoothPlastic", rot=None, shape=None,
         collide=True, touch=False, query=True, transparency=0, kind="Part", children=None):
    """An anchored part. Most backyard parts are looks only, so CanTouch is
    off by default (nothing here needs Touched except the pads)."""
    props = {
        "Size": [r(v) for v in size],
        "CFrame": {"CFrame": {"position": [r(v) for v in pos],
                              "orientation": [[rot6(v) for v in row] for row in (rot or IDENTITY)]}},
        "Color": {"Color3uint8": list(color)},
        "Anchored": True,
        "Material": material,
        "TopSurface": "Smooth",
        "BottomSurface": "Smooth",
    }
    if shape:
        props["Shape"] = shape
    if transparency:
        props["Transparency"] = transparency
    if not collide:
        props["CanCollide"] = False
    if not touch:
        props["CanTouch"] = False
    if not query:
        props["CanQuery"] = False
    node = {"name": name, "className": kind, "properties": props}
    if children:
        node["children"] = children
    return node


def decor(name, size, pos, color, **kw):
    """Looks only: never blocks players, fires Touched, or stops raycasts."""
    return part(name, size, pos, color, collide=False, query=False, **kw)


def model(name, children):
    return {"name": name, "className": "Model", "children": children}


def keypoints(*points):
    return {"NumberSequence": {"keypoints": [{"time": t, "value": v, "envelope": 0} for t, v in points]}}


def colors(*points):
    return {"ColorSequence": {"keypoints": [{"time": t, "color": list(c)} for t, c in points]}}


def stroke(thickness, mode):
    return {
        "name": "UIStroke",
        "className": "UIStroke",
        "properties": {"Color": DARK, "Thickness": thickness, "ApplyStrokeMode": mode, "LineJoinMode": "Round"},
    }


def text_label(text, size, stroke_px, rich, name="TextLabel", y=0.5):
    props = {
        "Text": text,
        "Font": "FredokaOne",
        "TextScaled": True,
        "TextColor3": [1, 1, 1],
        "TextStrokeTransparency": 1,
        "BackgroundTransparency": 1,
        "AnchorPoint": [0.5, 0.5],
        "Position": {"UDim2": [[0.5, 0], [y, 0]]},
        "Size": {"UDim2": [[size[0], 0], [size[1], 0]]},
    }
    if rich:
        props["RichText"] = True
    return {"name": name, "className": "TextLabel", "properties": props,
            "children": [stroke(stroke_px, "Contextual")]}


# --- trophy pads --------------------------------------------------------------

def pad(index, x, z, text):
    """Same structure as BuildButton1 (see GAME_DESIGN.md "Pad style")."""
    name = f"TrophyButton{index}"
    ring = {
        "name": f"{name}Ring",
        "className": "Part",
        "properties": {
            "Shape": "Cylinder",
            "Size": [0.2, 7.5, 7.5],
            "CFrame": {"CFrame": {"position": [r(x), r(G + 0.1), r(z)], "orientation": PAD_ROT}},
            "Color": {"Color3uint8": RING_COLOR},
            "Anchored": True,
            "CanTouch": False,
            "CanQuery": False,
            "Material": "SmoothPlastic",
            "TopSurface": "Smooth",
            "BottomSurface": "Smooth",
        },
    }
    label = {
        "name": "Label",
        "className": "BillboardGui",
        "properties": {"Size": {"UDim2": [[7, 0], [2.8, 0]]}, "StudsOffset": [0, 3.6, 0], "LightInfluence": 0},
        "children": [{
            "name": "Panel",
            "className": "Frame",
            "properties": {"Size": {"UDim2": [[1, 0], [1, 0]]}, "BackgroundColor3": PANEL_COLOR, "BorderSizePixel": 0},
            "children": [
                {"name": "UICorner", "className": "UICorner", "properties": {"CornerRadius": {"UDim": [0.35, 0]}}},
                stroke(4, "Border"),
                text_label(text, (0.88, 0.8), 2.5, True),
            ],
        }],
    }
    return {
        "name": name,
        "className": "Part",
        "properties": {
            "Size": [0.4, 6, 6],
            "CFrame": {"CFrame": {"position": [r(x), r(G + 0.2), r(z)], "orientation": PAD_ROT}},
            "Color": {"Color3uint8": PAD_COLOR},
            "Anchored": True,
            "Material": "SmoothPlastic",
            "TopSurface": "Smooth",
            "BottomSurface": "Smooth",
            "Shape": "Cylinder",
        },
        "children": [ring, label],
    }


def near_pad(x, z, margin):
    """True if (x, z) is within `margin` studs of a pad's ring."""
    return any(math.hypot(x - px, z - pz) < 3.75 + margin for _, _, px, pz, _ in PADS)


# --- pool -------------------------------------------------------------------
#
# A walk-in pool. The Ground is one big slab (y 0..1) shared by every plot,
# so instead of digging into it the pool is a raised basin standing on the
# grass: stone side walls up to the coping (COPING_TOP), a solid floor on the
# ground, and no-collision water filling it to just under the coping. You
# climb a few steps up to the coping, hop in (about waist deep) and run
# around; steps inside the front +X corner (nearest the back door) lead back
# up to the coping, with matching steps down to the grass on the outside.

POOL_X = (-30, -8)
POOL_Z = (-117, -80)
COPING_W = 2.0  # wide enough to walk around the pool on
COPING_TOP = G + 3.6  # floor -> coping about 3.4 studs: waist deep
COPING_CAP = 0.4  # the sand-colored cap on top of the side walls
POOL_FLOOR_TOP = G + 0.2
WATER_TOP = COPING_TOP - 0.4
STEP_TREAD = 1.6
STEP_WIDTH = 6.0  # along the +X wall, from the front corner back
STEP_COUNT = 3  # steps between the floor (or grass) and the coping
POOL_WALL = (214, 204, 182)
POOL_STEP = (240, 248, 252)


def steps(prefix, x_edge, direction, bottom, z0, z1, color, material="SmoothPlastic"):
    """STEP_COUNT blocks against the wall face at x_edge, going down from the
    coping in `direction` (+1 = +X, -1 = -X) to `bottom`. Each block stands
    on `bottom` and is one equal rise lower than the one before it."""
    rise = (COPING_TOP - bottom) / (STEP_COUNT + 1)
    out = []
    for k in range(1, STEP_COUNT + 1):
        top = COPING_TOP - k * rise
        xa = x_edge + direction * (k - 1) * STEP_TREAD
        xb = x_edge + direction * k * STEP_TREAD
        out.append(part(f"{prefix}{k}", (STEP_TREAD, top - bottom, z1 - z0),
                        ((xa + xb) / 2, (bottom + top) / 2, (z0 + z1) / 2), color, material))
    return out


def pool():
    x0, x1 = POOL_X
    z0, z1 = POOL_Z
    cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
    w, d = x1 - x0, z1 - z0
    c = COPING_W
    wall_top = COPING_TOP - COPING_CAP
    wh, wy = wall_top - G, (G + wall_top) / 2
    cap_y = wall_top + COPING_CAP / 2
    parts = [
        # Solid side walls standing on the grass, with the coping on top.
        part("PoolWallLeft", (c, wh, d), (x0 + c / 2, wy, cz), POOL_WALL, "Slate"),
        part("PoolWallRight", (c, wh, d), (x1 - c / 2, wy, cz), POOL_WALL, "Slate"),
        part("PoolWallFront", (w - 2 * c, wh, c), (cx, wy, z1 - c / 2), POOL_WALL, "Slate"),
        part("PoolWallBack", (w - 2 * c, wh, c), (cx, wy, z0 + c / 2), POOL_WALL, "Slate"),
        part("CopingLeft", (c, COPING_CAP, d), (x0 + c / 2, cap_y, cz), COPING),
        part("CopingRight", (c, COPING_CAP, d), (x1 - c / 2, cap_y, cz), COPING),
        part("CopingFront", (w - 2 * c, COPING_CAP, c), (cx, cap_y, z1 - c / 2), COPING),
        part("CopingBack", (w - 2 * c, COPING_CAP, c), (cx, cap_y, z0 + c / 2), COPING),
    ]
    ix0, ix1, iz0, iz1 = x0 + c, x1 - c, z0 + c, z1 - c
    iw, idp = ix1 - ix0, iz1 - iz0
    icx, icz = (ix0 + ix1) / 2, (iz0 + iz1) / 2
    floor_top = POOL_FLOOR_TOP
    lh, ly, t = wall_top - floor_top, (floor_top + wall_top) / 2, 0.1
    parts += [
        part("PoolFloor", (iw, floor_top - G, idp), (icx, (G + floor_top) / 2, icz), POOL_FLOOR),
        # Light blue lining on the inside of the walls (looks only).
        decor("LiningLeft", (t, lh, idp), (ix0 + t / 2, ly, icz), POOL_FLOOR),
        decor("LiningRight", (t, lh, idp), (ix1 - t / 2, ly, icz), POOL_FLOOR),
        decor("LiningFront", (iw, lh, t), (icx, ly, iz1 - t / 2), POOL_FLOOR),
        decor("LiningBack", (iw, lh, t), (icx, ly, iz0 + t / 2), POOL_FLOOR),
        # A dark blue lane line with a "T" at each end, on the floor.
        decor("LaneLine", (0.8, 0.05, idp - 7), (icx, floor_top + 0.025, icz), POOL_LANE),
        decor("LaneEndFront", (3, 0.05, 0.8), (icx, floor_top + 0.025, iz1 - 3.5), POOL_LANE),
        decor("LaneEndBack", (3, 0.05, 0.8), (icx, floor_top + 0.025, iz0 + 3.5), POOL_LANE),
        # Water you walk through: no collide, touch or query.
        decor("Water", (iw, WATER_TOP - floor_top, idp), (icx, (floor_top + WATER_TOP) / 2, icz), WATER,
              material="Glass", transparency=0.45),
    ]
    # Steps in the front +X corner: down into the water on the inside, down
    # to the grass on the outside, in one straight line across the coping.
    sz0, sz1 = iz1 - STEP_WIDTH, iz1
    parts += steps("PoolStep", ix1, -1, floor_top, sz0, sz1, POOL_STEP)
    parts += steps("DeckStep", x1, 1, G, sz0, sz1, COPING, "Slate")

    # Red brick garden wall along the pool's outer (-X) edge, with a stone cap.
    wall_x0, wall_x1, brick_top = -31.8, -30.2, COPING_TOP + 2.5
    wz0, wz1 = z0 - 1, z1 + 1
    wx = (wall_x0 + wall_x1) / 2
    parts += [
        part("BrickWall", (wall_x1 - wall_x0, brick_top - G, wz1 - wz0), (wx, (G + brick_top) / 2, (wz0 + wz1) / 2), RED_BRICK, "Brick"),
        part("BrickWallCap", (wall_x1 - wall_x0 + 0.4, 0.4, wz1 - wz0 + 0.4), (wx, brick_top + 0.2, (wz0 + wz1) / 2), WALL_CAP),
    ]
    for name, z in (("BrickPierFront", wz1 - 0.9), ("BrickPierMid", (wz0 + wz1) / 2), ("BrickPierBack", wz0 + 0.9)):
        parts.append(part(name, (2, brick_top - G + 0.8, 1.8), (wx, (G + brick_top + 0.8) / 2, z), RED_BRICK, "Brick"))
        parts.append(part(name + "Cap", (2.2, 0.4, 2.2), (wx, brick_top + 1.0, z), WALL_CAP))
    # Diving board at the far end: a stand behind the pool, the board resting
    # just above the back coping and reaching out over the water.
    bx = icx
    board_y = COPING_TOP + 0.45
    parts += [
        part("DivingStand", (2.4, board_y - 0.15 - G, 2.4), (bx, (G + board_y - 0.15) / 2, z0 - 1.2), BOARD_STAND),
        part("DivingBoard", (2, 0.3, 7.5), (bx, board_y, z0 + 2.45), BOARD),
        decor("DivingBoardTip", (2.1, 0.1, 0.6), (bx, board_y + 0.2, z0 + 5.9), BOARD_STAND),
    ]
    # Two beach balls floating in the water.
    parts += [
        decor("BeachBallRed", (1.6, 1.6, 1.6), (icx + 4, WATER_TOP + 0.3, icz + 3), (235, 64, 60), shape="Ball"),
        decor("BeachBallYellow", (1.2, 1.2, 1.2), (icx - 5, WATER_TOP + 0.2, icz - 8), (250, 214, 60), shape="Ball"),
    ]
    return model("Pool", parts)


# --- path ---------------------------------------------------------------------

PATH_X = (BACK_DOOR_X - 3, BACK_DOOR_X + 3)
PATH_Z = (-99, HOUSE_BACK - 3)  # from the back step to the patio


def backyard_path():
    rng = random.Random(7)  # fixed seed: re-runs give the same rocks
    x0, x1 = PATH_X
    z0, z1 = PATH_Z
    cx = (x0 + x1) / 2
    parts = [part("PathBase", (x1 - x0, 0.15, z1 - z0), (cx, G + 0.075, (z0 + z1) / 2), PATH_BASE, "Slate")]
    # Flagstones, rows alternating one wide stone / two half stones.
    gap = 0.35
    rows = round((z1 - z0 - gap) / (3.0 + gap))
    row = (z1 - z0 - gap) / rows - gap  # about 3 studs, filling the path exactly
    z = z1 - gap
    for i in range(rows):
        zc = z - row / 2
        h = 0.2 + 0.05 * (i % 3)
        if i % 2 == 0:
            stones = [(cx, x1 - x0 - 2 * gap)]
        else:
            half = (x1 - x0 - 3 * gap) / 2
            stones = [(x0 + gap + half / 2, half), (x1 - gap - half / 2, half)]
        for k, (sx, sw) in enumerate(stones, 1):
            color = FLAGSTONES[(i * 2 + k) % len(FLAGSTONES)]
            parts.append(part(f"Flagstone{i + 1}_{k}", (sw, h, row - gap), (sx, G + 0.15 + h / 2, zc), color, "Slate"))
        z -= row + gap
    # Rocks and dirt patches along both sides (kept off the pads).
    n = 0
    for side, sx in (("L", x0 - 1.4), ("R", x1 + 1.4)):
        z = z1 - 1.5
        k = 0
        while z > z0 + 0.5:
            k += 1
            if k % 3 == 0:
                d = rng.uniform(2.6, 3.6)
                x = sx + (-1 if side == "L" else 1) * rng.uniform(0.4, 1.2)
                if not near_pad(x, z, d / 2 + 0.5):
                    n += 1
                    parts.append(decor(f"Dirt{n}", (0.1, d, d), (x, G + 0.05, z), rng.choice(DIRT),
                                       material="Ground", rot=UPRIGHT, shape="Cylinder"))
                z -= d * 0.7
            else:
                d = rng.uniform(1.0, 2.0)
                x = sx + rng.uniform(-0.4, 0.4)
                if not near_pad(x, z, d / 2 + 0.5):
                    n += 1
                    parts.append(decor(f"Rock{n}", (d, d, d), (x, G + d * 0.22, z), rng.choice(ROCKS), material="Slate", shape="Ball"))
                z -= rng.uniform(1.8, 2.6)
    return model("BackyardPath", parts)


# --- hangout ------------------------------------------------------------------

PATIO_CENTER = (BACK_DOOR_X, -109)
PATIO_HALF = 10
PATIO_TOP = G + 0.5


def chair(index, angle, color):
    """A chunky cartoony outdoor chair `6.3` studs from the fire, facing it.
    `angle` 0 = on the house side of the fire."""
    fx, fz = PATIO_CENTER
    yaw = rot_y(angle)  # local -Z (the chair's front) turns to face the fire
    base = (fx + 6.3 * math.sin(math.radians(angle)), PATIO_TOP, fz + 6.3 * math.cos(math.radians(angle)))

    def at(lx, ly, lz):
        dx, dy, dz = apply(yaw, (lx, ly, lz))
        return (base[0] + dx, base[1] + dy, base[2] + dz)

    dark = tuple(max(0, v - 50) for v in color)
    name = f"Chair{index}"
    tilt = matmul(yaw, rot_x(14))  # back leans away from the fire
    return model(name, [
        part("Seat", (2.8, 0.45, 2.6), at(0, 1.45, 0), color, rot=yaw),
        part("Back", (2.8, 3.2, 0.4), at(0, 3.05, 1.45), color, rot=tilt),
        part("BackTop", (3.0, 0.4, 0.6), at(0, 4.6, 1.85), dark, rot=tilt),
        part("SideLeft", (0.35, 1.25, 2.6), at(-1.3, 0.62, 0), dark, rot=yaw),
        part("SideRight", (0.35, 1.25, 2.6), at(1.3, 0.62, 0), dark, rot=yaw),
        part("ArmLeft", (0.6, 0.3, 2.9), at(-1.55, 2.4, 0.1), color, rot=yaw),
        part("ArmRight", (0.6, 0.3, 2.9), at(1.55, 2.4, 0.1), color, rot=yaw),
        part("ArmPostLeft", (0.35, 1.0, 0.35), at(-1.55, 1.75, -1.1), dark, rot=yaw),
        part("ArmPostRight", (0.35, 1.0, 0.35), at(1.55, 1.75, -1.1), dark, rot=yaw),
    ])


def hangout():
    px, pz = PATIO_CENTER
    h = PATIO_HALF
    parts = [part("PatioBase", (2 * h, PATIO_TOP - G - 0.1, 2 * h), (px, G + (PATIO_TOP - G - 0.1) / 2, pz), PATIO_BORDER, "Slate")]
    # A 4 x 4 grid of stone tiles with darker grout lines between them.
    n, grout = 4, 0.35
    tile = (2 * h - grout * (n + 1)) / n
    for i in range(n):
        for j in range(n):
            tx = px - h + grout + tile / 2 + i * (tile + grout)
            tz = pz - h + grout + tile / 2 + j * (tile + grout)
            parts.append(part(f"Tile{i * n + j + 1}", (tile, 0.1, tile), (tx, PATIO_TOP - 0.05, tz), PATIO_TILES[(i + j) % 2], "Slate"))

    # Fire pit: ash bed, ring of chunky stones, crossed logs, fire. The Fire,
    # Embers and FireLight are saved disabled (like the Trophy Case's
    # CaseLight): PlotVisibility does not hide effects or lights, so the game
    # code turns them on only while the Hangout is shown.
    pit = [decor("Ash", (0.1, 4.6, 4.6), (px, PATIO_TOP + 0.05, pz), ASH, material="Slate", rot=UPRIGHT, shape="Cylinder")]
    stones = 11
    for k in range(stones):
        a = 360 * k / stones
        sx = px + 2.75 * math.sin(math.radians(a))
        sz = pz + 2.75 * math.cos(math.radians(a))
        hgt = 1.0 + 0.15 * (k % 2)
        pit.append(part(f"PitStone{k + 1}", (1.5, hgt, 1.1), (sx, PATIO_TOP + hgt / 2, sz), PIT_STONES[k % len(PIT_STONES)],
                        "Slate", rot=rot_y(a)))
    for k, a in enumerate((0, 60, 120), 1):
        pit.append(decor(f"Log{k}", (3.6, 0.6, 0.6), (px, PATIO_TOP + 0.4 + 0.3 * (k - 1) * 0.6, pz), LOG,
                         material="Wood", rot=rot_y(a), shape="Cylinder"))
    fire_core = decor("FireCore", (1, 1, 1), (px, PATIO_TOP + 1.4, pz), (255, 140, 40), transparency=1, children=[
        {"name": "Fire", "className": "Fire", "properties": {
            "Enabled": False, "Size": 5, "Heat": 8, "Color": [1, 0.5, 0.12], "SecondaryColor": [1, 0.82, 0.25]}},
        {"name": "Embers", "className": "ParticleEmitter", "properties": {
            "Enabled": False,
            "Rate": 7,
            "Lifetime": {"NumberRange": [1.4, 2.4]},
            "Speed": {"NumberRange": [3, 6]},
            "SpreadAngle": [25, 25],
            "Acceleration": [0, 1.5, 0],
            "Size": keypoints((0, 0.22), (1, 0)),
            "Transparency": keypoints((0, 0), (0.8, 0.2), (1, 1)),
            "Color": colors((0, (1, 0.85, 0.3)), (1, (1, 0.35, 0.1))),
            "LightEmission": 1,
        }},
        {"name": "FireLight", "className": "PointLight", "properties": {
            "Enabled": False, "Color": [1, 0.6, 0.25], "Brightness": 2, "Range": 18, "Shadows": False}},
    ])
    pit.append(fire_core)
    parts.append(model("FirePit", pit))

    # Chairs around the fire, leaving the side the path comes in from open.
    for k, a in enumerate((60, 120, 180, 240, 300), 1):
        parts.append(chair(k, a, CHAIR_COLORS[k - 1]))
    return model("Hangout", parts)


# --- fence and zone -----------------------------------------------------------

FENCE_IN = 32.0  # inside faces of the side fences (x = +-32)
BACK_FENCE_IN = YARD_BACK + 1  # inside face of the back fence (z = -120)


def fence_run(prefix, a, b, fixed, along_x, outward, end_posts=True):
    """One straight run of picket fence from a to b (along X or Z) on the
    line `fixed`; rails sit on the outward side of the pickets. With
    end_posts=False the first and last posts are left out (another run
    already has a post at that corner)."""
    parts = []
    length = abs(b - a)
    posts = max(2, round(length / 5.5) + 1)
    step = (b - a) / (posts - 1)

    def pos(t, y, out=0.0):
        return (t, y, fixed + out) if along_x else (fixed + out, y, t)

    def size(along, h, thick):
        return (along, h, thick) if along_x else (thick, h, along)

    for i in range(posts):
        if not end_posts and i in (0, posts - 1):
            continue
        t = a + step * i
        parts.append(part(f"{prefix}Post{i + 1}", size(1, FENCE_HEIGHT, 1), pos(t, G + FENCE_HEIGHT / 2, 0), WHITE_FENCE))
        parts.append(decor(f"{prefix}PostCap{i + 1}", size(1.4, 0.4, 1.4), pos(t, G + FENCE_HEIGHT + 0.2, 0), FENCE_CAP))
        parts.append(decor(f"{prefix}PostKnob{i + 1}", (0.8, 0.8, 0.8), pos(t, G + FENCE_HEIGHT + 0.65, 0), WHITE_FENCE, shape="Ball"))
    # Two rails along the whole run.
    mid = (a + b) / 2
    for k, y in enumerate((G + 2.2, G + 5.8), 1):
        parts.append(part(f"{prefix}Rail{k}", size(length, 0.5, 0.3), pos(mid, y, outward * 0.35), WHITE_FENCE))
    # Pickets between the posts, each with a pointed (diamond) top.
    pitch, width = 1.5, 0.9
    top = G + FENCE_HEIGHT - 0.6
    diamond_rot = rot_z(45) if along_x else rot_x(45)
    n = 0
    for i in range(posts - 1):
        s0, s1 = sorted((a + step * i, a + step * (i + 1)))
        inner = (s1 - s0) - 1  # space between the two posts
        count = max(1, int((inner + pitch - width) // pitch))
        used = count * width + (count - 1) * (pitch - width)
        start = s0 + 0.5 + (inner - used) / 2 + width / 2
        for j in range(count):
            n += 1
            t = start + j * pitch
            parts.append(part(f"{prefix}Picket{n}", size(width, top - (G + 0.4), 0.4), pos(t, (G + 0.4 + top) / 2, 0), WHITE_FENCE))
            parts.append(decor(f"{prefix}PicketTip{n}", size(0.64, 0.64, 0.4), pos(t, top, 0), WHITE_FENCE, rot=diamond_rot))
    return parts


def backyard_fence():
    side = FENCE_IN + 0.5  # fence line (post centers)
    back = BACK_FENCE_IN - 0.5
    start = HOUSE_BACK - 0.8  # first post touches the house's corner post
    parts = []
    parts += fence_run("Left", start, back, -side, along_x=False, outward=-1)
    parts += fence_run("Right", start, back, side, along_x=False, outward=1)
    parts += fence_run("Back", -side, side, back, along_x=True, outward=-1, end_posts=False)
    return model("BackyardFence", parts)


# --- back door ----------------------------------------------------------------

def back_door():
    x = BACK_DOOR_X
    open_x0 = x - BACK_DOOR_HALF + 0.4  # inside the house's gray frame trim
    open_x1 = x + BACK_DOOR_HALF - 0.4
    door_top = BACK_DOOR_TOP - 0.4
    w, h = open_x1 - open_x0, door_top - FLOOR
    zc = HOUSE_BACK + 0.5  # middle of the wall
    yc = FLOOR + h / 2
    door_looks = []
    for face, off in (("Out", -0.25), ("In", 0.25)):
        z = zc + off
        door_looks += [
            decor(f"WindowFrame{face}", (w - 1.4, 3.6, 0.1), (x, door_top - 2.6, z), DOOR_PANEL),
            decor(f"Window{face}", (w - 2.0, 3.0, 0.12), (x, door_top - 2.6, z), GLASS),
            decor(f"WindowBarV{face}", (0.2, 3.0, 0.16), (x, door_top - 2.6, z), DOOR_PANEL),
            decor(f"WindowBarH{face}", (w - 2.0, 0.2, 0.16), (x, door_top - 2.6, z), DOOR_PANEL),
            decor(f"PanelLeft{face}", (1.6, 3.6, 0.1), (x - 1.05, FLOOR + 2.6, z), DOOR_PANEL),
            decor(f"PanelRight{face}", (1.6, 3.6, 0.1), (x + 1.05, FLOOR + 2.6, z), DOOR_PANEL),
            decor(f"Knob{face}", (0.55, 0.55, 0.55), (open_x1 - 0.55, FLOOR + 4.6, zc + off * 1.8), GOLD, shape="Ball"),
            decor(f"KnobPlate{face}", (0.4, 1.1, 0.1), (open_x1 - 0.55, FLOOR + 4.6, z), GOLD),
        ]
    door = part("Door", (w, h, 0.4), (x, yc, zc), DOOR_WOOD, "Wood", children=door_looks)

    # Sign above the door on the inside, facing into the house (its Back
    # face points +Z, into the room). The game rewrites both labels
    # (BackyardDoor.luau): the lock message on top (two lines, TextScaled)
    # and the owner's "🏆 x/5" smaller under it. Tall enough for that, still
    # under the 2nd floor slab (y 17).
    sign_w, sign_h = 8, 3.6
    sign_y = BACK_DOOR_TOP + 0.4 + sign_h / 2
    sign = part("DoorSign", (sign_w, sign_h, 0.3), (x, sign_y, WALL_INNER + 0.15), GOLD, collide=False, query=False, children=[{
        "name": "SignGui",
        "className": "SurfaceGui",
        "properties": {"Face": "Back", "SizingMode": "PixelsPerStud", "PixelsPerStud": 50, "LightInfluence": 0},
        "children": [{
            "name": "Panel",
            "className": "Frame",
            "properties": {
                "AnchorPoint": [0.5, 0.5],
                "Position": {"UDim2": [[0.5, 0], [0.5, 0]]},
                "Size": {"UDim2": [[0.94, 0], [0.84, 0]]},
                "BackgroundColor3": PANEL_COLOR,
                "BorderSizePixel": 0,
            },
            "children": [
                {"name": "UICorner", "className": "UICorner", "properties": {"CornerRadius": {"UDim": [0.3, 0]}}},
                stroke(8, "Border"),
                text_label("🔒 Unlock this door once you have 5 Caleb Trophies", (0.9, 0.56), 4, True, y=0.36),
                text_label("", (0.5, 0.26), 4, True, name="ProgressLabel", y=0.8),
            ],
        }],
    }])

    # Outside: gray casing around the opening, a little awning, a stone step.
    out = HOUSE_BACK - 0.15
    x0, x1 = x - BACK_DOOR_HALF, x + BACK_DOOR_HALF
    step_top = G + (FLOOR - G) / 2
    casing_h = BACK_DOOR_TOP + 0.8 - step_top  # from the step up past the opening
    casing_y = step_top + casing_h / 2
    casing = [
        decor("CasingLeft", (0.8, casing_h, 0.3), (x0 - 0.4, casing_y, out), TRIM),
        decor("CasingRight", (0.8, casing_h, 0.3), (x1 + 0.4, casing_y, out), TRIM),
        decor("CasingTop", (2 * BACK_DOOR_HALF, 0.8, 0.3), (x, BACK_DOOR_TOP + 0.4, out), TRIM),
        decor("CasingCrown", (2 * BACK_DOOR_HALF + 2.4, 0.4, 0.7), (x, BACK_DOOR_TOP + 1.0, HOUSE_BACK - 0.35), TRIM),
        # Awning: a gray wedge sloping away from the wall (its tall side is +Z,
        # against the wall).
        decor("Awning", (2 * BACK_DOOR_HALF + 2.4, 1.2, 2.2), (x, BACK_DOOR_TOP + 1.8, HOUSE_BACK - 1.1), (96, 100, 104),
              material="Slate", kind="WedgePart"),
    ]
    step = part("BackStep", (2 * BACK_DOOR_HALF + 2, step_top - G, 3), (x, (G + step_top) / 2, HOUSE_BACK - 1.5), STEP_STONE, "Slate")
    return model("BackDoor", [door, sign] + casing + [step])


# --- main ---------------------------------------------------------------------

def count_parts(node):
    own = 1 if node["className"] in ("Part", "WedgePart") else 0
    return own + sum(count_parts(c) for c in node.get("children", []))


def main():
    with open(PLOT_FILE, encoding="utf-8") as f:
        plot = json.load(f)

    new = {
        "Pool": pool(),
        "BackyardPath": backyard_path(),
        "Hangout": hangout(),
        "BackyardFence": backyard_fence(),
        "BackDoor": back_door(),
    }
    for index, _, x, z, text in PADS:
        new[f"TrophyButton{index}"] = pad(index, x, z, text)

    children = plot["children"]
    children[:] = [c for c in children if c.get("name") not in REMOVED]
    for name in MANAGED:
        at = [i for i, c in enumerate(children) if c.get("name") == name]
        if at:
            children[at[0]] = new[name]
            for i in reversed(at[1:]):
                del children[i]  # never leave duplicates behind
        else:
            children.append(new[name])

    with open(PLOT_FILE, "w", encoding="utf-8") as f:
        f.write(json.dumps(plot, indent=2, ensure_ascii=False) + "\n")
    for name in MANAGED:
        print(f"{name}: {count_parts(new[name])} parts")


if __name__ == "__main__":
    main()
