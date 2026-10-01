#!/usr/bin/env python3
"""Generates src/Workspace/Map/Statue.model.json: a big cartoony statue.

Run from the repo root:   python3 tools/statue/generate_statue.py

The statue is made only of built-in Roblox parts (balls, blocks, cylinders)
plus a Highlight for a black cartoon outline. Edit the numbers below and
re-run this script instead of hand-editing the JSON (it is regenerated).

The statue is Caleb. Players feed him cookies on the four FeedPads around the
pedestal; StatueService (server) then grows the Belly, Cheeks, and Chin parts
made here and widens his body (see StatueShape.luau). Those parts start
hidden inside the body; their "not fed yet" positions below must match
StatueShape's formulas at fatness 0.

Look: a cartoon caricature (huge round head, big white eyes with tiny pupils,
wide toothy grin) with a smooth bald-style face, shaggy dark-brown hair with
messy bangs over the forehead and ears, a dark navy long-sleeve shirt, a thin
gold chain, and one hand on the hip.

Coordinates: built in "statue space" with the statue facing -Z, then moved by
STATUE_ORIGIN. The spawn is at (0, 1, 0) and the plot is toward -Z, so the
statue stands behind the spawn (+Z) and faces it: turn around after spawning
to see it. Rojo orientation lists are matrix ROWS (R00 R01 R02 first).
"""

import json
import math
import os
import random

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "src", "Workspace", "Map", "Statue.model.json")

STATUE_ORIGIN = (0.0, 1.0, 44.0)  # ground top (y = 1), behind the spawn

# Colors (RGB 0-255)
SKIN = (236, 190, 156)
HAIR = (82, 54, 34)
BROW = (70, 44, 28)
SHIRT = (32, 36, 56)  # dark navy long-sleeve
PANTS = (58, 64, 82)
SHOE = (245, 245, 245)
SOLE = (40, 40, 40)
EYE_WHITE = (255, 255, 255)
PUPIL = (20, 20, 20)
MOUTH = (60, 16, 20)
TEETH = (255, 255, 255)
GOLD = (255, 200, 60)
STONE = (150, 150, 158)
STONE_TOP = (190, 190, 198)

# Head
HEAD_CENTER = (0.0, 33.5, 0.0)
HEAD_R = 6.5

IDENTITY = [[1, 0, 0], [0, 1, 0], [0, 0, 1]]
parts = []


def add(v, w):
    return (v[0] + w[0], v[1] + w[1], v[2] + w[2])


def sub(v, w):
    return (v[0] - w[0], v[1] - w[1], v[2] - w[2])


def scale(v, s):
    return (v[0] * s, v[1] * s, v[2] * s)


def length(v):
    return math.sqrt(v[0] ** 2 + v[1] ** 2 + v[2] ** 2)


def unit(v):
    n = length(v)
    return (v[0] / n, v[1] / n, v[2] / n)


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def rows_from_columns(right, up, back):
    """Rotation matrix rows from the part's X (right), Y (up), Z (back) axes."""
    return [[right[i], up[i], back[i]] for i in range(3)]


def facing(normal, up_hint=(0, 1, 0)):
    """Rotation whose front (-Z) points along `normal` (thin faces show outward)."""
    look = unit(normal)
    right = cross(look, up_hint)
    if length(right) < 1e-6:
        right = (1, 0, 0)
    right = unit(right)
    up = unit(cross(right, look))
    return rows_from_columns(right, up, scale(look, -1))


def along_y(direction):
    """Rotation whose Y axis points along `direction` (for limbs)."""
    up = unit(direction)
    hint = (0, 0, 1) if abs(up[2]) < 0.9 else (1, 0, 0)
    right = unit(cross(up, hint))
    back = unit(cross(right, up))
    return rows_from_columns(right, up, back)


def rot_z(deg):
    a = math.radians(deg)
    c, s = math.cos(a), math.sin(a)
    return [[c, -s, 0], [s, c, 0], [0, 0, 1]]


def r(x):
    return round(x, 3)


def part(name, size, pos, color, shape=None, rot=None, material="SmoothPlastic", collide=True, touch=False, into=None):
    world = add(pos, STATUE_ORIGIN)
    props = {
        "Size": [r(s) for s in size],
        "CFrame": {
            "CFrame": {
                "position": [r(c) for c in world],
                "orientation": [[r(x) for x in row] for row in (rot or IDENTITY)],
            }
        },
        "Color": {"Color3uint8": list(color)},
        "Anchored": True,
        "CanTouch": touch,
        "Material": material,
        "TopSurface": "Smooth",
        "BottomSurface": "Smooth",
    }
    if not collide:
        props["CanCollide"] = False
        props["CanQuery"] = False
    if shape:
        props["Shape"] = shape
    node = {"name": name, "className": "Part", "properties": props}
    (parts if into is None else into).append(node)
    return node


def ball(name, diameter, pos, color, **kw):
    part(name, (diameter, diameter, diameter), pos, color, shape="Ball", **kw)


def limb(name, a, b, thickness, color):
    """A block from point a to point b."""
    d = sub(b, a)
    mid = scale(add(a, b), 0.5)
    part(name, (thickness, length(d), thickness), mid, color, rot=along_y(d))


def on_head(x, y, extra=0.0):
    """Point on the front (-Z) of the head sphere at local (x, y), pushed out by `extra`."""
    zz = math.sqrt(max(HEAD_R**2 - x * x - y * y, 0.0))
    p = (x, y, -zz)
    n = unit(p)
    return add(HEAD_CENTER, scale(n, HEAD_R + extra)), n


# Pedestal ------------------------------------------------------------------
part("PedestalBase", (26, 2, 26), (0, 1, 0), STONE)
part("PedestalTop", (21, 3, 21), (0, 3.5, 0), STONE_TOP)
part("PedestalTrim", (21.6, 0.6, 21.6), (0, 5.2, 0), GOLD, material="Neon")

FLOOR = 5.5  # top of the pedestal

# Legs and shoes ------------------------------------------------------------
for side, x in (("Right", 2.4), ("Left", -2.4)):
    part(f"{side}Leg", (3.6, 9.5, 3.8), (x, FLOOR + 1.0 + 4.75, 0), PANTS)
    part(f"{side}Shoe", (4.2, 1.6, 5.6), (x, FLOOR + 0.8 + 0.2, -0.8), SHOE)
    part(f"{side}Sole", (4.3, 0.4, 5.7), (x, FLOOR + 0.2, -0.8), SOLE)

# Torso (dark navy long-sleeve) ---------------------------------------------
TORSO_BOTTOM = FLOOR + 10.5
TORSO_TOP = TORSO_BOTTOM + 10.5
part("Torso", (10.5, TORSO_TOP - TORSO_BOTTOM, 5.6), (0, (TORSO_BOTTOM + TORSO_TOP) / 2, 0), SHIRT)
part("Belt", (10.6, 0.8, 5.7), (0, TORSO_BOTTOM + 0.3, 0), (30, 30, 30))
part("Neck", (3.4, 2.2, 3.4), (0, TORSO_TOP + 0.9, 0), SKIN, shape="Cylinder", rot=rot_z(90))

# Gold chain: small beads in a V across the chest, plus a little pendant.
for i in range(13):
    t = i / 12 * 2 - 1  # -1 .. 1
    x = t * 2.2
    y = TORSO_TOP - 0.6 - (1 - t * t) * 1.8
    ball(f"ChainBead{i + 1}", 0.45, (x, y, -2.85), GOLD, material="Neon", collide=False)
part("ChainPendant", (0.5, 0.9, 0.3), (0, TORSO_TOP - 2.9, -2.9), GOLD, material="Neon", collide=False)

# Belly: hidden inside the torso until Caleb is fed (StatueShape grows it).
ball("Belly", 5.0, (0, TORSO_BOTTOM + 3.0, 0), SHIRT)

# Arms: right arm (+X, the statue's right) hangs down; left hand on the hip.
SHOULDER_Y = TORSO_TOP - 1.2
r_sh = (5.8, SHOULDER_Y, 0)
r_hand = (7.4, TORSO_BOTTOM - 0.5, -0.4)
limb("RightArm", r_sh, r_hand, 3.0, SHIRT)
ball("RightHand", 3.0, add(r_hand, (0.1, -0.8, 0)), SKIN)

l_sh = (-5.8, SHOULDER_Y, 0)
l_elbow = (-10.2, TORSO_BOTTOM + 4.6, 0.4)
l_hip = (-5.9, TORSO_BOTTOM + 1.2, 0.2)
limb("LeftUpperArm", l_sh, l_elbow, 3.0, SHIRT)
limb("LeftForearm", l_elbow, l_hip, 2.8, SHIRT)
ball("LeftElbow", 3.0, l_elbow, SHIRT)
ball("LeftHand", 2.8, l_hip, SKIN)

# Head ----------------------------------------------------------------------
ball("Head", HEAD_R * 2, HEAD_CENTER, SKIN)
for side, x in (("Right", 1), ("Left", -1)):
    ball(f"{side}Ear", 2.4, add(HEAD_CENTER, (x * 6.3, -0.4, 0.4)), SKIN)

# Big round eyes that touch, tiny pupils looking slightly different ways.
for side, x, px in (("Right", 1.85, 1.6), ("Left", -1.85, -1.4)):
    p, n = on_head(x, 1.0, -1.25)
    ball(f"{side}Eye", 3.7, p, EYE_WHITE)
    pp, _ = on_head(px, 1.05, 0.45)
    ball(f"{side}Pupil", 0.85, pp, PUPIL)
    bp, bn = on_head(x * 1.05, 2.95, 0.5)
    part(f"{side}Brow", (2.6, 0.55, 0.5), bp, BROW, rot=facing(bn))

np_, _ = on_head(0, -0.9, -0.2)
ball("Nose", 1.6, np_, SKIN)

# Chubby cheeks and a double chin: hidden inside the head until Caleb is fed.
for side, x in (("Right", 1), ("Left", -1)):
    ball(f"{side}Cheek", 2.0, add(HEAD_CENTER, scale(unit((x * 5.0, -1.4, -3.4)), 4.6)), SKIN)
ball("Chin", 3.0, add(HEAD_CENTER, scale(unit((0, -0.93, -0.37)), 4.0)), SKIN)

# Wide grin: a curved mouth band with a row of teeth along its top edge.
N = 11
for i in range(N):
    t = i / (N - 1) * 2 - 1  # -1 .. 1
    x = t * 3.0
    y_mid = -2.9 + 0.9 * t * t  # corners turn up
    p, n = on_head(x, y_mid, 0.05)
    h = 1.9 - 1.1 * t * t  # mouth is tallest in the middle
    part(f"Mouth{i + 1}", (0.75, h, 0.4), p, MOUTH, rot=facing(n), collide=False)
    if abs(t) < 0.85:
        tp, tn = on_head(x, y_mid + h / 2 - 0.35, 0.12)
        part(f"Tooth{i + 1}", (0.62, 0.6, 0.3), tp, TEETH, rot=facing(tn), collide=False)

# Shaggy hair (dark brown, medium length, messy fringe, covers the ears).
# A smooth "cap" ball set up and back from the head makes the main shape: it
# meets the face at about forehead height and adds volume on top and behind.
# Clumps around its lower edge make it shaggy, and tilted strands make the
# fringe that falls over the forehead (swept toward the statue's right, +X).
rng = random.Random(9026)
CAP_OFFSET = (0.0, 1.2, 1.2)
CAP_R = HEAD_R + 0.4
ball("HairCap", CAP_R * 2, add(HEAD_CENTER, CAP_OFFSET), HAIR)

count = 0
# Shaggy edge: clumps from one temple, around the back, to the other temple.
for i in range(15):
    az = 65 + i * (230 / 14)  # degrees around the head; 0 = straight ahead (-Z)
    a = math.radians(az)
    back = (1 - math.cos(a)) / 2  # 0 at the front, 1 at the back
    y = 1.2 - 3.6 * back + rng.uniform(-0.4, 0.4)  # lower at the back (down to the neck)
    ring_r = HEAD_R + 0.1
    pos = (ring_r * math.sin(a), y, -ring_r * math.cos(a) + 0.8)
    count += 1
    ball(f"Hair{count}", 3.0 + rng.random() * 0.8, add(HEAD_CENTER, pos), HAIR)

# Messy tufts poking out of the top for a shaggy silhouette.
for dx, dy, dz, d in [(-3.0, 6.9, 0.2, 3.4), (1.2, 7.6, 0.8, 3.6), (4.0, 6.2, 1.6, 3.2), (-4.8, 5.2, 2.6, 3.2), (0.4, 6.6, 4.6, 3.4)]:
    count += 1
    ball(f"Hair{count}", d, add(HEAD_CENTER, (dx, dy, dz)), HAIR)

# Fringe: uneven strands hanging over the forehead, tilted to one side.
for x, y, tilt, h in [(-3.9, 4.3, 18, 3.0), (-2.6, 3.9, 22, 3.6), (-1.1, 4.0, 26, 3.3), (0.5, 3.8, 28, 3.7), (2.0, 4.1, 24, 3.2), (3.4, 4.4, 20, 2.8)]:
    p, n = on_head(x, y, 0.45)
    t = math.radians(tilt)
    count += 1
    part(f"Hair{count}", (1.9, h, 1.0), p, HAIR, rot=facing(n, (math.sin(t), math.cos(t), 0)))

# Feed pads: one on each side of the pedestal. Same pad style as the plot's
# pads (round pad + darker ring + cartoony sign). Touching one opens the feed
# prompt on that player's screen (FeedPrompt.client.luau); the server checks
# the player is really near a pad before taking any cookies.
PAD_COLOR = (255, 170, 40)
PAD_RING = (150, 80, 10)
SIGN_PANEL = [1.0, 0.549, 0.118]  # 255,140,30
OUTLINE = [0.157, 0.11, 0.078]  # 40,28,20, same dark outline as the cash display
PAD_ROT = [[0, -1, 0], [1, 0, 0], [0, 0, 1]]  # cylinder's round face points up
pads = []


def sign(text):
    return {
        "name": "Label",
        "className": "BillboardGui",
        "properties": {"Size": {"UDim2": [[8, 0], [1.9, 0]]}, "StudsOffset": [0, 3.2, 0], "LightInfluence": 0},
        "children": [
            {
                "name": "Panel",
                "className": "Frame",
                "properties": {"Size": {"UDim2": [[1, 0], [1, 0]]}, "BackgroundColor3": SIGN_PANEL, "BorderSizePixel": 0},
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
                                "properties": {"Color": OUTLINE, "Thickness": 2.5, "ApplyStrokeMode": "Contextual", "LineJoinMode": "Round"},
                            }
                        ],
                    },
                ],
            }
        ],
    }


for side, (x, z) in (("Front", (0, -18)), ("Back", (0, 18)), ("Left", (-18, 0)), ("Right", (18, 0))):
    pad = part(f"FeedPad{side}", (0.4, 6, 6), (x, 0.2, z), PAD_COLOR, shape="Cylinder", rot=PAD_ROT, touch=True, into=pads)
    ring = part(f"FeedPad{side}Ring", (0.2, 7.5, 7.5), (x, 0.1, z), PAD_RING, shape="Cylinder", rot=PAD_ROT, into=[])
    ring["properties"]["CanQuery"] = False
    pad["children"] = [ring, sign("FEED CALEB!")]

model = {
    "className": "Model",
    "children": parts
    + [{"name": "FeedPads", "className": "Folder", "children": pads}]
    + [
        {
            "name": "CartoonOutline",
            "className": "Highlight",
            "properties": {
                "FillTransparency": 1,
                "OutlineColor": [0, 0, 0],
                "OutlineTransparency": 0,
                "DepthMode": "Occluded",
            },
        }
    ],
}

with open(OUT, "w") as f:
    f.write(json.dumps(model, indent=2) + "\n")

top = max(
    p["properties"]["CFrame"]["CFrame"]["position"][1] + p["properties"]["Size"][1] / 2 for p in parts
)
print(f"Wrote {len(parts)} parts to {os.path.normpath(OUT)}; top of statue at y = {top:.1f} ({top - 1:.1f} studs tall)")
