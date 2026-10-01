#!/usr/bin/env python3
"""Adds the second-floor furniture (and its buy buttons) to Plot1.

Run from the repo root:   python3 tools/furniture/generate_furniture.py
Then run:                 python3 tools/plots/generate_plots.py

Cartoony versions of the user's real stuff (photos in agent-office/assets:
bedanddesk.jpg, tvandshelfs.jpg, miniFridge.jpg, ninja.jpg), laid out on the
second floor like the user's sketch (stairs on one side, the conveyor on the
other, shelves + TV along the front wall, desk and bed at the back):

  Bed             black headboard and frame, gray sheets, white + gray
                  pillows, a rumpled gray blanket
  GamingDesk      black L-shaped desk, 3 monitors (one standing up), webcam,
                  white/blue keyboard, mouse, controller, headphones, a cup,
                  black office chair, backpack on the floor
  ShelvesTV       dark cube bookshelf full of books with the Barad-dur LEGO
                  tower and a lime-green drill on top; cube TV stand with
                  board games and white bins, a TV, PS5, mushroom lamp, remote
  MiniFridge      black mini fridge with the orange LEGO moon rocket on top,
                  and a foam roller on the floor
  KitchenCounter  granite counter with a tile backsplash, the Ninja ice cream
                  maker, the Ninja blender, and a cast iron skillet

Each is a Model bought with its own orange BuildButtonN (Config.Builds
entries 5-9, all unlocked by "SecondFloor", the same time as Dropper 5). The
models are hidden until bought (PlotStages hides every build's Parts).

Only the instances named in MANAGED are rewritten; the rest of the plot file
is left exactly as it is. Plain parts only (no meshes, decals, or lights).
Edit the numbers here and re-run instead of hand-editing the JSON.

Coordinates are Plot1's (world) coordinates. The second floor's top is at
y = 18. Inside wall faces: front z = -11.25 (toward the statue), back
z = -74.75, left x = -31.75 (conveyor side), right x = 31.75 (stairs side).
"""

import json
import math
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PLOT_FILE = os.path.join(ROOT, "src", "Workspace", "Map", "Plots", "Plot1.model.json")

F = 18.0  # top of the second floor slab
FRONT = -11.25
BACK = -74.75
RIGHT = 31.75

IDENTITY = [[1, 0, 0], [0, 1, 0], [0, 0, 1]]

# Colors (RGB 0-255). Bright and simple for a cartoony look.
BLACK = (34, 34, 40)
CHARCOAL = (58, 58, 66)
SHEET = (150, 152, 168)
BLANKET = (118, 120, 132)
THROW = (170, 170, 180)
WHITE = (245, 245, 248)
SATIN = (178, 172, 200)
SCREEN_BLUE = (70, 150, 240)
SCREEN_GREEN = (80, 210, 120)
SCREEN_PURPLE = (150, 100, 230)
KEYS = (150, 200, 245)
SHELF_WOOD = (66, 46, 36)
LAVA = (255, 120, 30)
EYE = (255, 150, 20)
ROCK = (120, 120, 128)
TOWER = (30, 30, 34)
HORN = (120, 30, 24)
RYOBI = (205, 235, 40)
ORANGE_ROCKET = (225, 110, 40)
GRANITE = (196, 190, 184)
TILE = (248, 248, 244)
CABINET = (236, 228, 210)
SILVER = (180, 184, 190)
POWER_RED = (235, 60, 60)
BOOK_COLORS = [
    (220, 70, 60), (240, 150, 50), (250, 220, 90), (90, 170, 220), (70, 90, 170),
    (230, 230, 220), (150, 80, 160), (60, 150, 100), (200, 50, 80), (40, 40, 50),
]

# Buy buttons: (index in Config.Builds, model name, x, z). Keep these in the
# same order as Config.Builds entries 5-9.
BUTTONS = [
    (5, "Bed", -3, -55),
    (6, "GamingDesk", 11, -57),
    (7, "ShelvesTV", 8, -21),
    (8, "MiniFridge", 27.5, -63),
    (9, "KitchenCounter", -8, -21),
]
MANAGED = {name for _, name, _, _ in BUTTONS} | {f"BuildButton{i}" for i, _, _, _ in BUTTONS}


# --- helpers ----------------------------------------------------------------

def r(x):
    x = round(x, 3)
    return int(x) if x == int(x) else x


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


UPRIGHT = rot_z(90)  # a Cylinder's axis (X) pointing up
ALONG_Z = rot_y(90)  # a Cylinder's axis pointing along Z


class Item:
    """Collects the parts of one furniture model."""

    def __init__(self, name):
        self.name = name
        self.parts = []

    def part(self, name, size, pos, color, material="SmoothPlastic", rot=None, shape=None,
             collide=True, transparency=0, kind="Part"):
        props = {
            "Size": [r(s) for s in size],
            "CFrame": {"CFrame": {"position": [r(c) for c in pos],
                                  "orientation": [[r(v) for v in row] for row in (rot or IDENTITY)]}},
            "Color": {"Color3uint8": list(color)},
            "Anchored": True,
            "CanTouch": False,
            "Material": material,
            "TopSurface": "Smooth",
            "BottomSurface": "Smooth",
        }
        if shape:
            props["Shape"] = shape
        if not collide:
            props["CanCollide"] = False
            props["CanQuery"] = False
        if transparency:
            props["Transparency"] = transparency
        self.parts.append({"name": name, "className": kind, "properties": props})

    def ball(self, name, d, pos, color, material="SmoothPlastic", **kw):
        self.part(name, (d, d, d), pos, color, material, shape="Ball", **kw)

    def cyl(self, name, length, d, pos, color, material="SmoothPlastic", rot=UPRIGHT, **kw):
        """A cylinder `length` long (along `rot`'s X, upright by default)."""
        self.part(name, (length, d, d), pos, color, material, shape="Cylinder", rot=rot, **kw)

    def model(self):
        return {"name": self.name, "className": "Model", "children": self.parts}


# --- Bed --------------------------------------------------------------------

def bed():
    it = Item("Bed")
    x, head, length, width = -3.0, BACK, 13.0, 9.0
    zc = head + length / 2
    foot = head + length
    for i, (dx, dz) in enumerate(((-1, -1), (1, -1), (-1, 1), (1, 1)), 1):
        it.part(f"Leg{i}", (0.8, 0.6, 0.8), (x + dx * (width / 2 - 0.4), F + 0.3, zc + dz * (length / 2 - 0.4)), BLACK, "Wood")
    it.part("Frame", (width + 0.4, 1.4, length), (x, F + 1.3, zc), BLACK, "Wood")
    it.part("Mattress", (width - 0.2, 1.4, length - 0.8), (x, F + 2.7, zc + 0.2), SHEET, "Fabric")
    it.part("Headboard", (width + 0.6, 7.2, 0.8), (x, F + 3.6, head + 0.4), BLACK, "Wood")
    it.part("HeadboardPanel", (width - 1.4, 4.4, 0.2), (x, F + 4.4, head + 0.9), CHARCOAL, "Wood", collide=False)
    it.part("PillowWhite", (3.6, 1.0, 2.2), (x + 2.1, F + 3.9, head + 2.2), WHITE, "Fabric", rot=rot_x(-12), collide=False)
    it.part("PillowSatin", (3.6, 1.1, 2.3), (x - 2.1, F + 4.0, head + 2.3), SATIN, "Fabric", rot=rot_x(-18), collide=False)
    it.part("Blanket", (width, 0.5, 7.0), (x, F + 3.6, foot - 3.5), BLANKET, "Fabric")
    it.part("BlanketDrape", (width, 2.6, 0.5), (x, F + 2.6, foot + 0.05), BLANKET, "Fabric", collide=False)
    it.part("BlanketSide", (0.5, 2.0, 7.0), (x + width / 2 + 0.2, F + 2.8, foot - 3.5), BLANKET, "Fabric", collide=False)
    it.part("Throw", (5.0, 0.8, 3.4), (x + 0.8, F + 4.1, foot - 6.5), THROW, "Fabric", rot=rot_y(22), collide=False)
    it.part("ThrowLump", (2.6, 0.7, 2.0), (x - 1.6, F + 4.0, foot - 4.0), THROW, "Fabric", rot=rot_y(-30), collide=False)
    return it.model()


# --- Gaming desk ---------------------------------------------------------------

def monitor(it, name, x, z, width, height, screen_color, top):
    """A monitor on the desk facing +Z (into the room)."""
    it.part(f"{name}Foot", (1.8, 0.15, 1.0), (x, top + 0.075, z), CHARCOAL, collide=False)
    it.part(f"{name}Neck", (0.4, 1.0, 0.3), (x, top + 0.6, z - 0.1), CHARCOAL, collide=False)
    cy = top + 1.0 + height / 2
    it.part(name, (width, height, 0.3), (x, cy, z - 0.2), BLACK, collide=False)
    it.part(f"{name}Screen", (width - 0.3, height - 0.3, 0.05), (x, cy, z - 0.03), screen_color, collide=False)
    it.part(f"{name}Shine", (0.3, height - 0.6, 0.05), (x - width / 4, cy, z + 0.0), WHITE, collide=False,
            transparency=0.55, rot=rot_z(-20))
    return cy + height / 2


def gaming_desk():
    it = Item("GamingDesk")
    top = F + 3.4
    x0, x1 = 5.0, 19.0  # main top along the back wall
    depth = 4.0
    it.part("DeskTop", (x1 - x0, 0.5, depth), ((x0 + x1) / 2, top - 0.25, BACK + depth / 2), BLACK, "Wood")
    it.part("ReturnTop", (4.0, 0.5, 8.0), (x1 - 2.0, top - 0.25, BACK + depth + 4.0), BLACK, "Wood")
    it.part("SideLeft", (0.5, 2.9, depth), (x0 + 0.25, F + 1.45, BACK + depth / 2), BLACK, "Wood")
    it.part("SideRight", (0.5, 2.9, depth + 8.0), (x1 - 0.25, F + 1.45, BACK + (depth + 8.0) / 2), BLACK, "Wood")
    it.part("ReturnEnd", (3.5, 2.9, 0.5), (x1 - 2.25, F + 1.45, BACK + depth + 7.75), BLACK, "Wood")
    it.part("BackPanel", (x1 - x0 - 1.0, 1.8, 0.3), ((x0 + x1) / 2, F + 2.2, BACK + 0.3), CHARCOAL, "Wood", collide=False)

    z = BACK + 1.4
    monitor(it, "Monitor1", 8.6, z, 4.2, 2.5, SCREEN_BLUE, top)
    m2_top = monitor(it, "Monitor2", 13.0, z, 4.2, 2.5, SCREEN_GREEN, top)
    monitor(it, "Monitor3", 17.0, z, 2.5, 4.2, SCREEN_PURPLE, top)  # standing up
    it.part("Webcam", (0.9, 0.45, 0.5), (13.0, m2_top + 0.22, z - 0.2), BLACK, collide=False)
    it.ball("WebcamLens", 0.3, (13.0, m2_top + 0.22, z + 0.05), (60, 60, 70), collide=False)

    it.part("Keyboard", (3.4, 0.25, 1.2), (11.0, top + 0.125, BACK + 3.0), WHITE, collide=False)
    it.part("Keycaps", (3.0, 0.12, 0.8), (11.0, top + 0.3, BACK + 3.0), KEYS, collide=False)
    it.part("Mouse", (0.5, 0.25, 0.8), (13.6, top + 0.125, BACK + 3.0), BLACK, collide=False)
    it.part("Controller", (1.4, 0.4, 0.9), (17.0, top + 0.2, BACK + 8.0), WHITE, collide=False)
    it.part("ControllerTouchpad", (0.6, 0.1, 0.4), (17.0, top + 0.45, BACK + 7.9), BLACK, collide=False)
    for side, dx in (("Left", -0.4), ("Right", 0.4)):
        it.ball(f"ControllerStick{side}", 0.3, (17.0 + dx, top + 0.45, BACK + 8.2), BLACK, collide=False)
    # Headphones standing on the desk, cups facing sideways.
    for side, dx in (("Left", -0.7), ("Right", 0.7)):
        it.cyl(f"Headphone{side}", 0.45, 1.1, (6.4 + dx, top + 0.75, BACK + 2.4), BLACK, rot=IDENTITY, collide=False)
    it.part("HeadphoneBand", (1.8, 0.3, 0.45), (6.4, top + 1.55, BACK + 2.4), BLACK, collide=False)
    it.cyl("Cup", 0.9, 0.7, (7.6, top + 0.45, BACK + 3.4), WHITE, collide=False)

    # Office chair (black leather) facing the desk.
    cx, cz = 11.0, BACK + 6.2
    it.part("ChairSeat", (3.0, 0.6, 3.0), (cx, F + 2.4, cz), BLACK, "Leather")
    it.part("ChairBack", (3.0, 3.6, 0.7), (cx, F + 4.6, cz + 1.4), BLACK, "Leather", rot=rot_x(-8))
    for side, dx in (("Left", -1.6), ("Right", 1.6)):
        it.part(f"ChairArm{side}", (0.4, 0.4, 2.2), (cx + dx, F + 3.4, cz + 0.2), BLACK, "Leather", collide=False)
        it.part(f"ChairArmPost{side}", (0.3, 0.8, 0.3), (cx + dx, F + 2.9, cz + 0.6), CHARCOAL, collide=False)
    it.cyl("ChairPole", 1.6, 0.4, (cx, F + 1.3, cz), CHARCOAL)
    for i in range(5):
        a = i * 72
        dx, dz = math.sin(math.radians(a)) * 0.9, math.cos(math.radians(a)) * 0.9
        it.part(f"ChairLeg{i + 1}", (0.3, 0.25, 1.8), (cx + dx, F + 0.55, cz + dz), CHARCOAL, rot=rot_y(a), collide=False)
        it.ball(f"ChairWheel{i + 1}", 0.45, (cx + dx * 2, F + 0.22, cz + dz * 2), BLACK, collide=False)

    # Backpack on the floor between the desk and the bed.
    bx, bz = 3.2, BACK + 8.0
    it.part("Backpack", (1.8, 2.4, 1.1), (bx, F + 1.2, bz), BLACK, "Fabric", rot=rot_y(-15))
    it.part("BackpackPocket", (1.4, 1.0, 0.4), (bx + 0.2, F + 0.8, bz + 0.65), CHARCOAL, "Fabric", rot=rot_y(-15), collide=False)
    it.part("BackpackTop", (1.6, 0.4, 1.0), (bx, F + 2.5, bz), BLACK, "Fabric", rot=rot_y(-15), collide=False)
    return it.model()


# --- Shelves and TV ---------------------------------------------------------------

CUBE = 2.6  # one cube of the cube shelves
WOOD_T = 0.3
DEPTH = 2.8


def cube_shelf(it, prefix, x_left, cols, rows):
    """Cube shelving against the front wall, open side facing -Z. x_left is
    its +X edge (the shelves run toward -X). Returns cube centers by (col, row)."""
    width = cols * CUBE + WOOD_T
    height = rows * CUBE + WOOD_T
    xc = x_left - width / 2
    zc = FRONT - DEPTH / 2
    it.part(f"{prefix}Back", (width, height, 0.2), (xc, F + height / 2, FRONT - 0.1), SHELF_WOOD, "Wood")
    for i in range(cols + 1):
        x = x_left - WOOD_T / 2 - i * CUBE
        it.part(f"{prefix}Upright{i + 1}", (WOOD_T, height, DEPTH), (x, F + height / 2, zc), SHELF_WOOD, "Wood")
    for j in range(rows + 1):
        y = F + WOOD_T / 2 + j * CUBE
        it.part(f"{prefix}Shelf{j + 1}", (width, WOOD_T, DEPTH), (xc, y, zc), SHELF_WOOD, "Wood")
    centers = {}
    for i in range(cols):
        for j in range(rows):
            centers[(i, j)] = (x_left - WOOD_T - CUBE / 2 + WOOD_T / 2 - i * CUBE, F + WOOD_T + j * CUBE + (CUBE - WOOD_T) / 2, zc)
    return F + height, centers


def books(it, prefix, center, seed):
    """A row of books standing in one cube."""
    x, y, z = center
    inner = CUBE - WOOD_T - 0.2
    floor = y - (CUBE - WOOD_T) / 2
    widths = [0.38, 0.32, 0.42, 0.36, 0.3, 0.4]
    cursor = x + inner / 2
    for k in range(5):
        w = widths[(k + seed) % len(widths)]
        h = 1.5 + ((k * 7 + seed * 3) % 5) * 0.15
        color = BOOK_COLORS[(k * 3 + seed) % len(BOOK_COLORS)]
        it.part(f"{prefix}Book{k + 1}", (w, h, 1.9), (cursor - w / 2, floor + h / 2, z - 0.1), color, collide=False)
        cursor -= w + 0.02


def shelves_tv():
    it = Item("ShelvesTV")
    # Bookshelf: 2 x 3 cubes, nearest the stairs (photo: left of the TV).
    shelf_top, cubes = cube_shelf(it, "Bookshelf", 19.25, 2, 3)
    seed = 0
    for (col, row), c in sorted(cubes.items()):
        if (col, row) == (1, 2):
            # Headphones lying in the top cube.
            x, y, z = c
            for side, dx in (("Left", -0.6), ("Right", 0.6)):
                it.cyl(f"ShelfHeadphone{side}", 0.4, 1.0, (x + dx, y - 0.5, z), BLACK, rot=IDENTITY, collide=False)
            it.part("ShelfHeadphoneBand", (1.6, 0.25, 0.4), (x, y + 0.15, z), BLACK, collide=False)
        else:
            seed += 1
            books(it, f"Cube{col + 1}{row + 1}", c, seed)

    # Barad-dur LEGO tower on top, the Eye glowing between two horns.
    tx, tz = 17.0, FRONT - DEPTH / 2
    y = shelf_top
    it.part("TowerLava", (3.6, 0.3, 2.4), (tx, y + 0.15, tz), LAVA, collide=False)
    it.part("TowerRock", (2.8, 0.7, 2.0), (tx, y + 0.65, tz), ROCK, collide=False)
    it.part("TowerBase", (2.0, 1.0, 1.6), (tx, y + 1.5, tz), TOWER, collide=False)
    it.part("TowerMid", (1.5, 0.9, 1.3), (tx, y + 2.45, tz), TOWER, collide=False)
    it.part("TowerTop", (1.1, 0.7, 1.0), (tx, y + 3.25, tz), TOWER, collide=False)
    for side, dx, tilt in (("Left", -0.45, 14), ("Right", 0.45, -14)):
        it.part(f"TowerHorn{side}", (0.3, 1.2, 0.4), (tx + dx, y + 4.0, tz), HORN, rot=rot_z(tilt), collide=False)
    it.ball("Eye", 0.7, (tx, y + 3.9, tz - 0.05), EYE, "Neon", collide=False)
    it.part("EyePupil", (0.12, 0.5, 0.1), (tx, y + 3.9, tz - 0.4), BLACK, collide=False)

    # Ryobi drill (lime green) next to the tower.
    dx_, dz_ = 14.5, FRONT - 1.6
    it.part("DrillBattery", (0.9, 0.5, 1.1), (dx_, y + 0.25, dz_), CHARCOAL, collide=False)
    it.part("DrillHandle", (0.5, 1.2, 0.6), (dx_, y + 1.1, dz_), RYOBI, collide=False)
    it.part("DrillBody", (0.6, 0.7, 1.6), (dx_, y + 1.95, dz_ - 0.3), RYOBI, collide=False)
    it.part("DrillBit", (0.15, 0.15, 0.7), (dx_, y + 1.95, dz_ - 1.45), SILVER, collide=False)

    # TV stand: 4 x 2 cubes.
    stand_left = 19.25 - (2 * CUBE + WOOD_T) - 0.6
    stand_top, cubes = cube_shelf(it, "TVStand", stand_left, 4, 2)
    for (col, row), (x, cy, z) in cubes.items():
        if (col, row) in ((1, 0), (3, 1)):
            it.part(f"Bin{col + 1}{row + 1}", (2.0, 2.0, 2.0), (x, cy - 0.15, z - 0.2), WHITE, "Fabric", collide=False)
        elif col == 0:
            for k in range(3):
                color = BOOK_COLORS[(k * 4 + row * 2 + 3) % len(BOOK_COLORS)]
                floor = cy - (CUBE - WOOD_T) / 2
                it.part(f"Game{row + 1}{k + 1}", (2.0, 0.55, 1.9), (x, floor + 0.3 + k * 0.58, z - 0.1), color, collide=False)

    stand_w = 4 * CUBE + WOOD_T
    sx = stand_left - stand_w / 2
    tz = FRONT - DEPTH / 2
    it.part("TVFoot", (2.4, 0.2, 1.2), (sx, stand_top + 0.1, tz), BLACK, collide=False)
    it.part("TVNeck", (0.5, 0.6, 0.3), (sx, stand_top + 0.5, tz + 0.2), BLACK, collide=False)
    tv_cy = stand_top + 0.8 + 2.1
    it.part("TV", (7.2, 4.2, 0.4), (sx, tv_cy, tz + 0.2), BLACK, collide=False)
    it.part("TVScreen", (6.8, 3.8, 0.05), (sx, tv_cy, tz - 0.03), SCREEN_BLUE, collide=False)
    it.part("TVShine", (0.5, 3.0, 0.05), (sx - 1.8, tv_cy, tz - 0.07), WHITE, collide=False, transparency=0.55, rot=rot_z(-20))
    it.part("Remote", (0.3, 0.15, 1.0), (sx + 1.2, stand_top + 0.08, tz - 0.8), BLACK, collide=False)

    # PS5 standing up (white plates, black middle) on the stairs side of the TV.
    px = stand_left - 0.9
    it.part("PS5Core", (0.5, 2.6, 1.9), (px, stand_top + 1.3, tz), BLACK, collide=False)
    for side, dx in (("Left", -0.35), ("Right", 0.35)):
        it.part(f"PS5Plate{side}", (0.2, 2.9, 2.1), (px + dx, stand_top + 1.45, tz), WHITE, collide=False)

    # White mushroom lamp at the far end.
    lx = stand_left - stand_w + 0.9
    it.cyl("LampStem", 1.0, 0.6, (lx, stand_top + 0.5, tz), WHITE, collide=False)
    it.ball("LampShade", 1.5, (lx, stand_top + 1.35, tz), (255, 246, 225), "Neon", collide=False)
    return it.model()


# --- Mini fridge + LEGO rocket -----------------------------------------------------

def mini_fridge():
    it = Item("MiniFridge")
    w, h, d = 3.4, 4.6, 3.2
    x, z = RIGHT - 0.4 - w / 2, BACK + 0.3 + d / 2
    front = z + d / 2
    it.part("Body", (w, h, d), (x, F + h / 2, z), BLACK)
    it.part("Door", (w - 0.1, h - 0.3, 0.1), (x, F + h / 2, front + 0.05), (44, 44, 50), collide=False)
    it.part("Handle", (2.6, 0.25, 0.35), (x, F + h - 0.6, front + 0.25), CHARCOAL, collide=False)
    it.part("Logo", (1.2, 0.2, 0.05), (x + 0.8, F + h - 1.1, front + 0.12), SILVER, collide=False)

    # LEGO SLS moon rocket on its black launch base, with its tower.
    y = F + h
    rz = z
    it.part("LaunchBase", (2.4, 0.5, 1.8), (x, y + 0.25, rz), BLACK, collide=False)
    it.part("LaunchStripe", (0.4, 0.2, 0.1), (x + 0.8, y + 0.3, rz + 0.92), POWER_RED, collide=False)
    it.part("Tower", (0.3, 6.2, 0.3), (x, y + 0.5 + 3.1, rz - 0.75), BLACK, collide=False)
    for k, ty in enumerate((1.6, 3.0, 4.4)):
        it.part(f"TowerArm{k + 1}", (0.15, 0.15, 0.7), (x, y + 0.5 + ty, rz - 0.4), BLACK, collide=False)
    core_bottom = y + 0.5
    it.cyl("CoreStage", 3.6, 0.8, (x, core_bottom + 1.8, rz), ORANGE_ROCKET, collide=False)
    it.cyl("UpperStage", 1.2, 0.7, (x, core_bottom + 4.2, rz), WHITE, collide=False)
    it.cyl("Capsule", 0.5, 0.6, (x, core_bottom + 5.05, rz), WHITE, collide=False)
    it.part("EscapeTower", (0.12, 0.9, 0.12), (x, core_bottom + 5.75, rz), WHITE, collide=False)
    for side, dx in (("Left", -0.65), ("Right", 0.65)):
        it.cyl(f"Booster{side}", 3.4, 0.4, (x + dx, core_bottom + 1.7, rz), WHITE, collide=False)
        it.ball(f"BoosterTip{side}", 0.4, (x + dx, core_bottom + 3.4, rz), WHITE, collide=False)

    # Foam roller lying on the floor.
    it.cyl("FoamRoller", 2.2, 0.9, (x - 6.0, F + 0.45, BACK + 1.3), (70, 74, 80), rot=IDENTITY)
    return it.model()


# --- Kitchen counter + Ninja stuff ---------------------------------------------------

def kitchen_counter():
    it = Item("KitchenCounter")
    xc, w, d, h = -8.0, 9.0, 3.2, 3.4
    zc = FRONT - d / 2
    front = zc - d / 2
    it.part("Cabinet", (w, h - 0.4, d), (xc, F + (h - 0.4) / 2, zc), CABINET, "Wood")
    for k, dx in enumerate((-2.25, 2.25)):
        it.part(f"DoorSeam{k + 1}", (0.1, h - 1.0, 0.05), (xc + dx, F + 1.5, front - 0.03), (180, 170, 150), collide=False)
        it.part(f"Knob{k + 1}", (0.25, 0.6, 0.2), (xc + dx - 0.4 if k == 0 else xc + dx + 0.4, F + 2.2, front - 0.1), SILVER, collide=False)
    it.part("Countertop", (w + 0.4, 0.4, d + 0.3), (xc, F + h - 0.2, zc - 0.15), GRANITE, "Granite")
    it.part("Backsplash", (w + 0.4, 2.0, 0.2), (xc, F + h + 1.0, FRONT - 0.1), TILE, "CeramicTiles", collide=False)
    top = F + h
    iz = zc - 0.2

    # Ninja Creami: round base, clear pint bowl with handle, tall motor head.
    cx = xc
    it.cyl("CreamiBase", 0.5, 2.6, (cx, top + 0.25, iz), BLACK)
    it.cyl("CreamiRing", 0.15, 2.65, (cx, top + 0.45, iz), SILVER, collide=False)
    it.cyl("CreamiBowl", 1.9, 1.8, (cx, top + 1.45, iz), (150, 140, 170), "Glass", transparency=0.35, collide=False)
    it.part("CreamiHandle", (0.35, 1.5, 0.35), (cx - 1.2, top + 1.5, iz), (150, 140, 170), "Glass", transparency=0.35, collide=False)
    it.cyl("CreamiLid", 0.4, 2.1, (cx, top + 2.6, iz), BLACK, collide=False)
    it.part("CreamiTower", (1.9, 5.0, 1.4), (cx, top + 2.9, iz + 1.0), SILVER, "Metal")
    it.part("CreamiHead", (2.1, 2.6, 2.2), (cx, top + 4.4, iz + 0.3), BLACK)
    it.part("CreamiPanel", (1.6, 2.0, 0.05), (cx, top + 4.5, iz - 0.82), (52, 52, 60), collide=False)
    it.cyl("CreamiPower", 0.08, 0.45, (cx - 0.35, top + 3.7, iz - 0.86), POWER_RED, rot=ALONG_Z, collide=False)
    it.part("CreamiLogo", (0.9, 0.2, 0.05), (cx, top + 5.2, iz - 0.86), SILVER, collide=False)

    # Ninja blender: dark base, control panel, clear jar, black lid. (Photo:
    # skillet, ice cream maker, blender from left to right, seen from the room.)
    bx = xc - 3.0
    it.part("BlenderBase", (2.0, 2.0, 2.0), (bx, top + 1.0, iz), (70, 72, 80), "Metal")
    it.part("BlenderPanel", (1.6, 0.8, 0.05), (bx, top + 0.8, iz - 1.03), BLACK, collide=False)
    it.ball("BlenderButton", 0.3, (bx - 0.4, top + 0.85, iz - 1.05), POWER_RED, collide=False)
    it.part("BlenderJar", (1.6, 2.8, 1.6), (bx, top + 3.4, iz), (200, 220, 230), "Glass", transparency=0.4, collide=False)
    it.part("BlenderLid", (1.7, 0.3, 1.7), (bx, top + 4.95, iz), BLACK, collide=False)

    # Cast iron skillet with its handle sticking out.
    sx = xc + 3.0
    it.cyl("Skillet", 0.35, 2.8, (sx, top + 0.18, iz), (30, 30, 32))
    it.cyl("SkilletInside", 0.05, 2.3, (sx, top + 0.36, iz), (52, 50, 50), collide=False)
    it.part("SkilletHandle", (1.6, 0.2, 0.4), (sx + 2.0, top + 0.3, iz), (30, 30, 32), collide=False)
    return it.model()


# --- Buy buttons (same style as BuildButton1-4) -----------------------------------------

PAD_ROT = [[0, -1, 0], [1, 0, 0], [0, 0, 1]]
OUTLINE = [0.157, 0.11, 0.078]


def button(index, x, z, text):
    name = f"BuildButton{index}"
    return {
        "name": name,
        "className": "Part",
        "properties": {
            "Size": [0.4, 6, 6],
            "CFrame": {"CFrame": {"position": [r(x), F + 0.2, r(z)], "orientation": PAD_ROT}},
            "Color": {"Color3uint8": [255, 140, 0]},
            "Anchored": True,
            "Material": "SmoothPlastic",
            "TopSurface": "Smooth",
            "BottomSurface": "Smooth",
            "Shape": "Cylinder",
        },
        "children": [
            {
                "name": f"{name}Ring",
                "className": "Part",
                "properties": {
                    "Shape": "Cylinder",
                    "Size": [0.2, 7.5, 7.5],
                    "CFrame": {"CFrame": {"position": [r(x), F + 0.1, r(z)], "orientation": PAD_ROT}},
                    "Color": {"Color3uint8": [140, 70, 0]},
                    "Anchored": True,
                    "CanTouch": False,
                    "CanQuery": False,
                    "Material": "SmoothPlastic",
                    "TopSurface": "Smooth",
                    "BottomSurface": "Smooth",
                },
            },
            {
                "name": "Label",
                "className": "BillboardGui",
                "properties": {"Size": {"UDim2": [[7, 0], [2.8, 0]]}, "StudsOffset": [0, 3.6, 0], "LightInfluence": 0},
                "children": [
                    {
                        "name": "Panel",
                        "className": "Frame",
                        "properties": {"Size": {"UDim2": [[1, 0], [1, 0]]}, "BackgroundColor3": [1.0, 0.6, 0.15], "BorderSizePixel": 0},
                        "children": [
                            {"name": "UICorner", "className": "UICorner", "properties": {"CornerRadius": {"UDim": [0.35, 0]}}},
                            {"name": "UIStroke", "className": "UIStroke",
                             "properties": {"Color": OUTLINE, "Thickness": 4, "ApplyStrokeMode": "Border", "LineJoinMode": "Round"}},
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
                                    {"name": "UIStroke", "className": "UIStroke",
                                     "properties": {"Color": OUTLINE, "Thickness": 2.5, "ApplyStrokeMode": "Contextual", "LineJoinMode": "Round"}}
                                ],
                            },
                        ],
                    }
                ],
            },
        ],
    }


def main():
    with open(PLOT_FILE, encoding="utf-8") as f:
        plot = json.load(f)

    builders = {
        "Bed": bed,
        "GamingDesk": gaming_desk,
        "ShelvesTV": shelves_tv,
        "MiniFridge": mini_fridge,
        "KitchenCounter": kitchen_counter,
    }
    new = []
    total = 0
    for index, name, x, z in BUTTONS:
        model = builders[name]()
        total += len(model["children"])
        new.append(button(index, x, z, name))  # BuyButtons sets the real label text
        new.append(model)

    plot["children"] = [c for c in plot["children"] if c["name"] not in MANAGED] + new
    with open(PLOT_FILE, "w", encoding="utf-8") as f:
        f.write(json.dumps(plot, indent=2, ensure_ascii=False) + "\n")
    print(f"Wrote {len(BUTTONS)} furniture models ({total} parts) and their buttons to {os.path.relpath(PLOT_FILE, ROOT)}")


if __name__ == "__main__":
    main()
