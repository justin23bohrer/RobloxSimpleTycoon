#!/usr/bin/env python3
"""Rebuilds the plot's house parts in src/Workspace/Map/Plots/Plot1.model.json.

Run from the repo root:   python3 tools/house/generate_house.py

The tycoon building looks like a two-story suburban house: off-white brick
walls, gray trim (corner posts, a band between the floors, door frame,
fascia), dark windows with gray frames and grilles (an arched one above the
doorway), and a gray shingle gable roof.

Only the children of two plot models are rewritten; everything else in the
plot file is left exactly as it is:

  Walls        first-floor walls (bought with "Build Walls")
  SecondFloor  floor slab with the stair hole, second-story walls, and the
               roof (bought with "2nd Floor")

The part names and sizes of the walls and floor slabs match the earlier
plain version, so the plot layout (doorway, stair hole, heights) is the same.
Edit the numbers below and re-run this script instead of hand-editing the
JSON. Plain parts only: no textures, decals, or meshes.
"""

import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PLOT_FILE = os.path.join(ROOT, "src", "Workspace", "Map", "Plots", "Plot1.model.json")

# Colors (RGB 0-255) and materials.
BRICK = [238, 235, 228]  # off-white painted brick
BRICK_MATERIAL = "Brick"
TRIM = [122, 126, 130]  # gray outlining
GLASS = [44, 50, 58]  # dark window glass
ROOF = [96, 100, 104]  # gray shingles
ROOF_MATERIAL = "Slate"
RIDGE = [78, 82, 86]
FLOOR = [200, 200, 200]

# The plot (see GAME_DESIGN.md -> Plot layout). Walls are 1 thick; their
# outer faces are at x = +-33, z = -10 (front) and z = -76 (back).
X_OUT = 33
Z_FRONT = -10
Z_BACK = -76
GROUND_Y = 2  # top of the plot's Base
FLOOR1_TOP = 17  # top of the first-floor walls = bottom of the 2nd floor slab
FLOOR2_Y = 18  # top of the 2nd floor slab
WALL2_TOP = 31  # top of the second-story walls = bottom of the roof
DOOR_HALF = 8  # the front doorway is x -8..8
DOOR_TOP = 13  # doorway height (a brick header fills 13..17)
ROOF_HEIGHT = 14
ROOF_OVERHANG = 1

IDENTITY = [[1, 0, 0], [0, 1, 0], [0, 0, 1]]
TURN_180 = [[-1, 0, 0], [0, 1, 0], [0, 0, -1]]


def r(x):
    x = round(x, 3)
    return int(x) if x == int(x) else x


def part(name, size, pos, color, material="SmoothPlastic", class_name="Part", rot=None, shape=None, decor=False):
    props = {
        "Size": [r(v) for v in size],
        "CFrame": {"CFrame": {"position": [r(v) for v in pos], "orientation": rot or IDENTITY}},
        "Color": {"Color3uint8": color},
        "Anchored": True,
        "Material": material,
        "TopSurface": "Smooth",
        "BottomSurface": "Smooth",
    }
    if shape:
        props["Shape"] = shape
    if decor:
        # Looks only: never blocks players, fires Touched, or stops raycasts.
        props["CanCollide"] = False
        props["CanTouch"] = False
        props["CanQuery"] = False
    return {"name": name, "className": class_name, "properties": props}


def model(name, children):
    return {"name": name, "className": "Model", "children": children}


def brick(name, size, pos):
    return part(name, size, pos, BRICK, BRICK_MATERIAL)


def trim(name, size, pos):
    return part(name, size, pos, TRIM, decor=True)


# --- Windows -------------------------------------------------------------
# A wall face is described by its outward normal: "front" (+Z), "back" (-Z),
# "left" (-X), "right" (+X). `along` is the position along the wall (x for
# front/back, z for left/right).

FACES = {
    "front": ((0, 0, 1), Z_FRONT),
    "back": ((0, 0, -1), Z_BACK),
    "left": ((-1, 0, 0), -X_OUT),
    "right": ((1, 0, 0), X_OUT),
}


def on_face(face, along, y, out):
    """World position `out` studs outside a wall face (negative = inside)."""
    (nx, _, nz), plane = FACES[face]
    if nx:
        return (plane + nx * out, y, along)
    return (along, y, plane + nz * out)


def flat_size(face, width, height, depth):
    """Box size for something `width` wide along the wall, `depth` thick."""
    (nx, _, _), _ = FACES[face]
    return (depth, height, width) if nx else (width, height, depth)


def cylinder_rot(face):
    """Cylinder axis (its local X) pointing out of the wall."""
    (nx, _, nz), _ = FACES[face]
    # columns: X -> normal, Y -> up, Z -> X cross Y
    cx, cy, cz = (nx, 0, nz), (0, 1, 0), (-nz, 0, nx)
    return [[cx[0], cy[0], cz[0]], [cx[1], cy[1], cz[1]], [cx[2], cy[2], cz[2]]]


def window(name, face, along, center_y, width, height, panes=2, arch=False, inside=True):
    """A dark window with a gray frame, grilles, and a sill, plus (unless
    inside=False) a plain frame + glass on the inside of the 1-stud wall."""
    parts = []
    wall_inside = -1  # the wall's inner face is 1 stud in from the outer face
    # Frame panel behind the glass, glass on top, grilles on the glass.
    parts.append(part("Frame", flat_size(face, width + 0.8, height + 0.8, 0.3), on_face(face, along, center_y, 0.15), TRIM, decor=True))
    parts.append(part("Glass", flat_size(face, width, height, 0.3), on_face(face, along, center_y, 0.25), GLASS, decor=True))
    for i in range(1, panes):
        offset = -width / 2 + width * i / panes
        parts.append(part(f"GrilleV{i}", flat_size(face, 0.25, height, 0.1), on_face(face, along + offset, center_y, 0.45), TRIM, decor=True))
    parts.append(part("GrilleH", flat_size(face, width, 0.25, 0.1), on_face(face, along, center_y, 0.45), TRIM, decor=True))
    parts.append(part("Sill", flat_size(face, width + 1.2, 0.4, 0.7), on_face(face, along, center_y - height / 2 - 0.4, 0.35), TRIM, decor=True))
    if arch:
        top = center_y + height / 2
        rot = cylinder_rot(face)
        parts.append(part("ArchFrame", (0.3, width + 0.8, width + 0.8), on_face(face, along, top, 0.15), TRIM, rot=rot, shape="Cylinder", decor=True))
        parts.append(part("ArchGlass", (0.3, width, width), on_face(face, along, top, 0.25), GLASS, rot=rot, shape="Cylinder", decor=True))
    if not inside:
        return model(name, parts)
    # Inside view of the same window.
    parts.append(part("InsideFrame", flat_size(face, width + 0.8, height + 0.8, 0.2), on_face(face, along, center_y, wall_inside - 0.1), TRIM, decor=True))
    parts.append(part("InsideGlass", flat_size(face, width, height, 0.2), on_face(face, along, center_y, wall_inside - 0.15), GLASS, decor=True))
    return model(name, parts)


def corner_posts(prefix, bottom, top):
    height = top - bottom
    y = bottom + height / 2
    posts = []
    for side, x in (("Left", -X_OUT + 0.5), ("Right", X_OUT - 0.5)):
        for end, z in (("Front", Z_FRONT - 0.5), ("Back", Z_BACK + 0.5)):
            posts.append(trim(f"{prefix}Corner{end}{side}", (1.6, height, 1.6), (x, y, z)))
    return posts


def bands(prefix, y, height, skip_doorway=False):
    """Gray trim strips around the outside of the house at height y."""
    thick = 0.3
    out = []
    length_x = 2 * X_OUT + 2 * thick
    if skip_doorway:
        piece = X_OUT - DOOR_HALF
        for side, sign in (("Left", -1), ("Right", 1)):
            out.append(trim(f"{prefix}Front{side}", (piece, height, thick), (sign * (DOOR_HALF + piece / 2), y, Z_FRONT + thick / 2)))
    else:
        out.append(trim(f"{prefix}Front", (length_x, height, thick), (0, y, Z_FRONT + thick / 2)))
    out.append(trim(f"{prefix}Back", (length_x, height, thick), (0, y, Z_BACK - thick / 2)))
    length_z = Z_FRONT - Z_BACK
    mid_z = (Z_FRONT + Z_BACK) / 2
    out.append(trim(f"{prefix}Left", (thick, height, length_z), (-X_OUT - thick / 2, y, mid_z)))
    out.append(trim(f"{prefix}Right", (thick, height, length_z), (X_OUT + thick / 2, y, mid_z)))
    return out


# The stairs run along the inside of the right wall over this z range, so
# first-floor windows there get no inside view (it would sink into the steps).
STAIRS_Z = (-52, -20)

# Window spots shared by both floors (along-wall positions).
SIDE_WINDOWS = (-22, -43, -64)  # z on the left and right walls
BACK_WINDOWS = (-20, 0, 20)  # x on the back wall


def walls():
    h = FLOOR1_TOP - GROUND_Y
    y = GROUND_Y + h / 2
    mid_z = (Z_FRONT + Z_BACK) / 2
    piece = X_OUT - 1 - DOOR_HALF  # front wall piece between corner and doorway
    children = [
        brick("WallLeft", (1, h, 66), (-X_OUT + 0.5, y, mid_z)),
        brick("WallRight", (1, h, 66), (X_OUT - 0.5, y, mid_z)),
        brick("WallBack", (64, h, 1), (0, y, Z_BACK + 0.5)),
        brick("WallFrontLeft", (piece, h, 1), (-(DOOR_HALF + piece / 2), y, Z_FRONT - 0.5)),
        brick("WallFrontRight", (piece, h, 1), (DOOR_HALF + piece / 2, y, Z_FRONT - 0.5)),
        # Brick above the doorway, so it reads as a garage-style opening.
        brick("DoorHeader", (2 * DOOR_HALF, FLOOR1_TOP - DOOR_TOP, 1), (0, (DOOR_TOP + FLOOR1_TOP) / 2, Z_FRONT - 0.5)),
        # Gray frame around the doorway.
        trim("DoorFrameLeft", (0.6, DOOR_TOP - GROUND_Y, 1.4), (-DOOR_HALF + 0.3, (GROUND_Y + DOOR_TOP) / 2, Z_FRONT - 0.5)),
        trim("DoorFrameRight", (0.6, DOOR_TOP - GROUND_Y, 1.4), (DOOR_HALF - 0.3, (GROUND_Y + DOOR_TOP) / 2, Z_FRONT - 0.5)),
        trim("DoorFrameTop", (2 * DOOR_HALF, 0.6, 1.4), (0, DOOR_TOP - 0.3, Z_FRONT - 0.5)),
    ]
    children += corner_posts("", GROUND_Y, FLOOR1_TOP)
    children += bands("Plinth", GROUND_Y + 0.4, 0.8, skip_doorway=True)
    # Band along the top of the first floor (the 2nd floor slab's gray edge
    # sits right on top of it once built).
    children += bands("FloorBand", FLOOR1_TOP - 0.5, 1, skip_doorway=False)

    w_y, w_w, w_h = 9, 4, 6
    windows = []
    for i, x in enumerate((-26, -16, 16, 26), 1):
        windows.append(window(f"WindowFront{i}", "front", x, w_y, w_w, w_h))
    for side in ("left", "right"):
        for i, z in enumerate(SIDE_WINDOWS, 1):
            by_stairs = side == "right" and STAIRS_Z[0] <= z <= STAIRS_Z[1]
            windows.append(window(f"Window{side.title()}{i}", side, z, w_y, w_w, w_h, inside=not by_stairs))
    for i, x in enumerate(BACK_WINDOWS, 1):
        windows.append(window(f"WindowBack{i}", "back", x, w_y, w_w, w_h))
    children.append(model("Windows", windows))
    return children


def roof():
    depth = (Z_FRONT - Z_BACK) / 2 + ROOF_OVERHANG
    width = 2 * X_OUT + 2 * ROOF_OVERHANG
    ridge_z = (Z_FRONT + Z_BACK) / 2
    y = WALL2_TOP + ROOF_HEIGHT / 2
    # A WedgePart's slope faces its front (-Z) with the tall side at +Z. The
    # back half keeps that; the front half is turned around to face the street.
    return model("Roof", [
        part("RoofFront", (width, ROOF_HEIGHT, depth), (0, y, ridge_z + depth / 2), ROOF, ROOF_MATERIAL, "WedgePart", TURN_180),
        part("RoofBack", (width, ROOF_HEIGHT, depth), (0, y, ridge_z - depth / 2), ROOF, ROOF_MATERIAL, "WedgePart"),
        part("Ridge", (width + 0.4, 0.8, 1.4), (0, WALL2_TOP + ROOF_HEIGHT + 0.1, ridge_z), RIDGE, decor=True),
        trim("FasciaFront", (width + 0.2, 0.8, 0.4), (0, WALL2_TOP + 0.2, Z_FRONT + ROOF_OVERHANG + 0.1)),
        trim("FasciaBack", (width + 0.2, 0.8, 0.4), (0, WALL2_TOP + 0.2, Z_BACK - ROOF_OVERHANG - 0.1)),
        front_gable(),
    ])


# Wedges turned so their slope faces -X / +X (their length runs along Z).
SLOPE_LEFT = [[0, 0, 1], [0, 1, 0], [-1, 0, 0]]
SLOPE_RIGHT = [[0, 0, -1], [0, 1, 0], [1, 0, 0]]
GABLE_HALF = 9  # the front gable spans x -9..9, over the arched window
GABLE_HEIGHT = 8


def front_gable():
    """A small pointed roof facing the street, with a brick triangle and a
    round vent, poking out of the main roof's front slope.

    Wedges are solid, so the gable roof's front end is a gray triangle; the
    brick triangle sits 1 stud in front of it, a little smaller, so the
    roof's edges outline it in gray."""
    # Reaches back until the main roof is as tall as the gable.
    depth_main = (Z_FRONT - Z_BACK) / 2 + ROOF_OVERHANG
    back_z = Z_FRONT + ROOF_OVERHANG - depth_main * GABLE_HEIGHT / ROOF_HEIGHT
    front_z = Z_FRONT
    length = front_z - back_z
    mid_z = (front_z + back_z) / 2
    y = WALL2_TOP + GABLE_HEIGHT / 2
    half = GABLE_HALF
    inset = 0.8  # the brick triangle sits under the gable's roof edges
    tri_half, tri_h = half - inset, GABLE_HEIGHT - inset * GABLE_HEIGHT / half
    tri_y = WALL2_TOP + tri_h / 2
    return model("FrontGable", [
        part("GableRoofLeft", (length, GABLE_HEIGHT, half), (-half / 2, y, mid_z), ROOF, ROOF_MATERIAL, "WedgePart", SLOPE_LEFT),
        part("GableRoofRight", (length, GABLE_HEIGHT, half), (half / 2, y, mid_z), ROOF, ROOF_MATERIAL, "WedgePart", SLOPE_RIGHT),
        part("GableBrickLeft", (1, tri_h, tri_half), (-tri_half / 2, tri_y, Z_FRONT + 0.5), BRICK, BRICK_MATERIAL, "WedgePart", SLOPE_LEFT),
        part("GableBrickRight", (1, tri_h, tri_half), (tri_half / 2, tri_y, Z_FRONT + 0.5), BRICK, BRICK_MATERIAL, "WedgePart", SLOPE_RIGHT),
        part("GableVent", (0.3, 2.2, 2.2), (0, WALL2_TOP + 3, Z_FRONT + 1.15), TRIM, rot=cylinder_rot("front"), shape="Cylinder", decor=True),
        part("GableVentHole", (0.3, 1.6, 1.6), (0, WALL2_TOP + 3, Z_FRONT + 1.25), GLASS, rot=cylinder_rot("front"), shape="Cylinder", decor=True),
    ])


def second_floor():
    slab_y = FLOOR1_TOP + 0.5
    floor = lambda name, size, pos: part(name, size, pos, FLOOR)
    children = [
        # Slab with a hole for the stairs at x 26..32, z -20..-52 (same as before).
        floor("FloorMain", (59, 1, 66), (-3.5, slab_y, -43)),
        floor("FloorBackRight", (7, 1, 24), (29.5, slab_y, -64)),
        floor("FloorFrontRight", (7, 1, 10), (29.5, slab_y, -15)),
        floor("FloorRightEdge", (1, 1, 32), (32.5, slab_y, -36)),
        # Railings around the stair hole (solid, so nobody falls in).
        part("HoleRailSide", (0.6, 3, 32), (25.7, FLOOR2_Y + 1.5, -36), TRIM),
        part("HoleRailFront", (6, 3, 0.6), (29, FLOOR2_Y + 1.5, -19.7), TRIM),
    ]
    h = WALL2_TOP - FLOOR2_Y
    y = FLOOR2_Y + h / 2
    mid_z = (Z_FRONT + Z_BACK) / 2
    children += [
        brick("Wall2Left", (1, h, 66), (-X_OUT + 0.5, y, mid_z)),
        brick("Wall2Right", (1, h, 66), (X_OUT - 0.5, y, mid_z)),
        brick("Wall2Back", (64, h, 1), (0, y, Z_BACK + 0.5)),
        brick("Wall2Front", (64, h, 1), (0, y, Z_FRONT - 0.5)),
    ]
    children += corner_posts("Upper", FLOOR2_Y, WALL2_TOP)

    w_y, w_w, w_h = 25, 4, 5
    windows = [
        window("WindowFront1", "front", -25, w_y, w_w, w_h),
        window("WindowFront2", "front", -15, w_y, w_w, w_h),
        # Arched window above the doorway.
        window("WindowFrontArch", "front", 0, w_y - 0.5, w_w, w_h - 1, panes=2, arch=True),
        # Wide double window on the right.
        window("WindowFrontWide", "front", 19, w_y, 8, w_h, panes=4),
    ]
    for side in ("left", "right"):
        for i, z in enumerate(SIDE_WINDOWS, 1):
            windows.append(window(f"Window{side.title()}{i}", side, z, w_y, w_w, w_h))
    for i, x in enumerate(BACK_WINDOWS, 1):
        windows.append(window(f"WindowBack{i}", "back", x, w_y, w_w, w_h))
    children.append(model("Windows", windows))
    children.append(roof())
    return children


def count_parts(nodes):
    return sum((1 if n["className"] != "Model" else 0) + count_parts(n.get("children", [])) for n in nodes)


def main():
    with open(PLOT_FILE, encoding="utf-8") as f:
        plot = json.load(f)
    builders = {"Walls": walls, "SecondFloor": second_floor}
    found = set()
    for child in plot["children"]:
        builder = builders.get(child.get("name"))
        if builder:
            child["children"] = builder()
            found.add(child["name"])
    missing = set(builders) - found
    if missing:
        raise SystemExit(f"Plot1.model.json has no {', '.join(sorted(missing))} model")
    with open(PLOT_FILE, "w", encoding="utf-8") as f:
        f.write(json.dumps(plot, indent=2, ensure_ascii=False) + "\n")
    for child in plot["children"]:
        if child.get("name") in builders:
            print(f"{child['name']}: {count_parts(child['children'])} parts")
    print(f"Roof top at y = {WALL2_TOP + ROOF_HEIGHT}")


if __name__ == "__main__":
    main()
