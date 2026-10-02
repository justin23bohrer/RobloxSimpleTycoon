"""The GarageCar model: a cartoony white Volkswagen ID.4 (2021-2024).

A compact electric SUV: smooth rounded white body, black roof and pillars
over dark windows, black wheel arches and lower trim, slim headlights joined
by a light bar, the VW roundel on the nose and the tailgate, a red light bar
across the back, 4 side doors + tailgate, and silver/black wheels.

Built in the car's own coordinates (x across, y up from the floor, z toward
the nose) and moved to `origin` (the floor point under the middle of the
car); the nose points +Z. Decoration only: everything is Anchored and only
the big body blocks are solid.
"""

import math

from parts import ALONG_Z, Parts, TURN_180, UPRIGHT, rot_x

WHITE = (243, 244, 246)
BLACK = (26, 26, 30)
GLASS = (30, 36, 46)
SEAM = (150, 152, 158)
SILVER = (196, 200, 206)
HEADLIGHT = (40, 44, 52)
LIGHT = (235, 245, 255)
TAIL = (120, 16, 20)
TAIL_LIGHT = (240, 40, 40)
PLATE = (250, 250, 250)

HALF_W = 3.5  # body sides at x = +-3.5
NOSE, TAIL_Z = 6.8, -7.0  # ends of the main body block (rounded caps go 0.5 further)
BELT = 4.3  # window line
ROOF_Y = 5.95  # top of the windows
AXLE = 4.7  # wheels at z = +-4.7
WHEEL_D = 3.2


def build(origin):
    ox, oy, oz = origin
    car = Parts("GarageCar")

    def at(p):
        return (ox + p[0], oy + p[1], oz + p[2])

    def box(name, lo, hi, color, material="SmoothPlastic", **kw):
        car.box(name, at(lo), at(hi), color, material, **kw)

    def part(name, size, pos, color, **kw):
        car.part(name, size, at(pos), color, **kw)

    def cyl(name, length, d, pos, color, **kw):
        car.cyl(name, length, d, at(pos), color, **kw)

    def beam(name, a, b, w, h, color, **kw):
        car.beam(name, at(a), at(b), w, h, color, **kw)

    # --- Body: one big white block with rounded nose and tail ------------
    box("Body", (-HALF_W, 0.9, TAIL_Z), (HALF_W, 3.9, NOSE), WHITE, collide=True)
    box("Belt", (-HALF_W, 3.9, TAIL_Z), (HALF_W, BELT, 2.6), WHITE, collide=True)
    # Hood: slopes down from the windshield (z 2.6) to the nose.
    part("Hood", (2 * HALF_W, BELT - 3.9, NOSE - 2.6), (0, (3.9 + BELT) / 2, (2.6 + NOSE) / 2), WHITE,
         rot=TURN_180, kind="WedgePart", collide=True)
    for name, z, top in (("Nose", NOSE, 3.4), ("Tail", TAIL_Z, 3.8)):
        out = 0.5 if z > 0 else -0.5
        box(f"{name}Face", (-3.0, 1.2, z), (3.0, top, z + out), WHITE)
        cyl(f"{name}TopRound", 6.0, 1.0, (0, top, z), WHITE, rot=None)
        for side in (-1, 1):
            cyl(f"{name}Corner{'LR'[side > 0]}", top - 1.2, 1.0, (side * 3.0, (1.2 + top) / 2, z), WHITE, rot=UPRIGHT)
            car.ball(f"{name}CornerTop{'LR'[side > 0]}", 1.0, at((side * 3.0, top, z)), WHITE)

    # --- Greenhouse: dark glass, black roof and pillars -------------------
    glass_w = 2 * HALF_W - 0.4
    box("SideGlass", (-glass_w / 2, BELT, -5.6), (glass_w / 2, ROOF_Y, 0.4), GLASS, collide=True)
    part("Windshield", (glass_w, ROOF_Y - BELT, 2.2), (0, (BELT + ROOF_Y) / 2, 1.5), GLASS,
         rot=TURN_180, kind="WedgePart")
    part("RearWindow", (glass_w, ROOF_Y - BELT, 1.4), (0, (BELT + ROOF_Y) / 2, -6.3), GLASS, kind="WedgePart")
    box("Roof", (-3.4, ROOF_Y, -5.9), (3.4, ROOF_Y + 0.4, 0.65), BLACK, collide=True)
    cyl("RoofFrontRound", 6.8, 0.4, (0, ROOF_Y + 0.2, 0.65), BLACK, rot=None)
    box("Spoiler", (-3.2, ROOF_Y + 0.15, -6.6), (3.2, ROOF_Y + 0.4, -5.9), BLACK)
    for z, name in ((-1.6, "PillarB"), (-4.3, "PillarC")):
        box(name, (-glass_w / 2 - 0.05, BELT, z - 0.25), (glass_w / 2 + 0.05, ROOF_Y, z + 0.25), BLACK)
    for side in (-1, 1):
        s = "LR"[side > 0]
        x = side * 3.25
        beam(f"PillarA{s}", (x, BELT, 2.6), (x, ROOF_Y + 0.05, 0.4), 0.35, 0.35, BLACK)
        beam(f"PillarD{s}", (x, ROOF_Y + 0.05, -5.6), (x, BELT, TAIL_Z), 0.35, 0.35, BLACK)
        cyl(f"RoofRail{s}", 6.0, 0.18, (side * 2.85, ROOF_Y + 0.5, -2.6), SILVER, rot=ALONG_Z)
        # Mirror on a short arm, by the bottom of the A-pillar.
        box(f"MirrorArm{s}", (side * 3.4, 4.35, 1.85), (side * 3.75, 4.55, 2.15), BLACK)
        box(f"Mirror{s}", (side * 3.7, 4.2, 1.7), (side * 4.45, 4.8, 2.4), BLACK)

    # --- Sides: black sill trim, door seams + handles, wheels -------------
    sx = HALF_W + 0.04
    for side in (-1, 1):
        s = "LR"[side > 0]
        box(f"Sill{s}", (side * 3.45, 0.8, TAIL_Z), (side * 3.58, 1.45, NOSE), BLACK)
        for i, z in enumerate((2.4, -1.6, -4.3), 1):
            box(f"DoorSeam{s}{i}", (side * 3.48, 1.45, z - 0.03), (side * sx, BELT, z + 0.03), SEAM)
        box(f"DoorLine{s}", (side * 3.48, BELT - 0.03, -4.3), (side * sx, BELT + 0.03, 2.4), SEAM)
        for i, z in enumerate((0.6, -3.0), 1):
            box(f"Handle{s}{i}", (side * 3.48, 3.55, z - 0.4), (side * (sx + 0.02), 3.75, z + 0.4), SEAM)
        for end, z in (("Front", AXLE), ("Rear", -AXLE)):
            wheel(car, at, f"{end}{s}", side, z)
    # Charge port flap on the right rear (the car's right is -X).
    box("ChargePort", (-sx - 0.02, 3.0, -5.9), (-3.48, 3.6, -5.2), SEAM)

    # --- Front: slim headlights, light bar, VW roundel, black bumper -----
    front = NOSE + 0.5
    for side in (-1, 1):
        s = "LR"[side > 0]
        box(f"Headlight{s}", (side * 1.4, 2.85, front - 0.05), (side * 3.1, 3.4, front + 0.08), HEADLIGHT)
        box(f"HeadlightDRL{s}", (side * 1.5, 3.2, front + 0.05), (side * 3.0, 3.3, front + 0.12), LIGHT, "Neon")
    box("LightBarFront", (-1.4, 3.13, front - 0.05), (1.4, 3.21, front + 0.08), LIGHT, "Neon")
    logo(car, at((0, 2.55, front + 0.04)), 0.95, 1)
    box("BumperFront", (-3.3, 0.8, NOSE + 0.05), (3.3, 1.75, front + 0.15), BLACK)
    box("IntakeFront", (-2.0, 0.95, front + 0.15), (2.0, 1.45, front + 0.2), (60, 62, 68))
    box("PlateFront", (-1.0, 0.95, front + 0.2), (1.0, 1.5, front + 0.25), PLATE)

    # --- Back: red light bar, VW roundel, tailgate seams, bumper ---------
    back = TAIL_Z - 0.5
    for side in (-1, 1):
        s = "LR"[side > 0]
        box(f"Taillight{s}", (side * 1.5, 3.05, back - 0.1), (side * 3.1, 3.6, back + 0.05), TAIL)
        box(f"TaillightGlow{s}", (side * 1.6, 3.25, back - 0.15), (side * 3.0, 3.38, back - 0.05), TAIL_LIGHT, "Neon")
        box(f"TailgateSeam{s}", (side * 2.84, 1.75, back - 0.04), (side * 2.9, 3.8, back + 0.02), SEAM)
        box(f"Reflector{s}", (side * 2.6, 1.05, back - 0.2), (side * 3.1, 1.3, back - 0.1), TAIL_LIGHT)
    box("LightBarRear", (-1.5, 3.27, back - 0.1), (1.5, 3.36, back + 0.05), TAIL_LIGHT, "Neon")
    logo(car, at((0, 2.55, back - 0.04)), 0.95, -1)
    box("BumperRear", (-3.3, 0.8, back - 0.15), (3.3, 1.75, TAIL_Z - 0.05), BLACK)
    box("PlateRear", (-1.0, 0.95, back - 0.2), (1.0, 1.5, back - 0.15), PLATE)
    # Rear wiper lying on the tailgate glass.
    slope = lambda t, x: at((x, BELT + (ROOF_Y - BELT) * t + 0.08, TAIL_Z + 1.4 * t - 0.05))
    car.beam("RearWiper", slope(0.15, 0), slope(0.45, 1.8), 0.12, 0.08, BLACK, up=(0, 0.57, -0.82))
    return car.model()


def wheel(car, at, name, side, z):
    """Black tire, silver rim with black spokes and cap, black arch around it."""
    y = WHEEL_D / 2
    x = side * (HALF_W - 0.45)
    car.cyl(f"Arch{name}", 0.16, 3.9, at((side * (HALF_W + 0.03), y, z)), BLACK, rot=None)
    car.cyl(f"Tire{name}", 1.2, WHEEL_D, at((x, y, z)), BLACK, rot=None)
    car.cyl(f"Rim{name}", 0.15, 2.1, at((x + side * 0.65, y, z)), SILVER, "Metal", rot=None)
    for i, deg in enumerate((0, 60, 120), 1):
        car.part(f"Spoke{name}{i}", (0.1, 0.32, 1.95), at((x + side * 0.74, y, z)), BLACK, rot=rot_x(deg))
    car.cyl(f"Cap{name}", 0.1, 0.6, at((x + side * 0.8, y, z)), BLACK, rot=None)
    car.cyl(f"CapRing{name}", 0.08, 0.8, at((x + side * 0.77, y, z)), SILVER, "Metal", rot=None)


def logo(car, center, d, facing):
    """The flat VW roundel: a silver ring around a dark disc with a silver
    V on top and W below. `facing` is +1 (looks toward +Z) or -1."""
    cx, cy, cz = center
    disc_rot = ALONG_Z
    tag = "Front" if facing > 0 else "Back"
    car.cyl(f"Logo{tag}Ring", 0.08, d, center, SILVER, "Metal", rot=disc_rot)
    car.cyl(f"Logo{tag}Disc", 0.1, d * 0.82, center, (24, 40, 80), rot=disc_rot)
    half = d / 2 * 0.82
    # Seen from the front of the roundel; x is mirrored when it faces -Z so
    # the letters still read the right way round from behind the car.
    strokes = {
        "V": ((-0.5, 0.82), (0, -0.02), (0.5, 0.82)),
        "W": ((-0.9, 0.36), (-0.42, -0.84), (0, -0.2), (0.42, -0.84), (0.9, 0.36)),
    }
    z = cz + facing * 0.07
    for letter, points in strokes.items():
        pts = [(cx + facing * px * half, cy + py * half, z) for px, py in points]
        for i, (a, b) in enumerate(zip(pts, pts[1:]), 1):
            car.beam(f"Logo{tag}{letter}{i}", a, b, d * 0.1, 0.07, SILVER, "Metal", up=(0, 0, 1))
