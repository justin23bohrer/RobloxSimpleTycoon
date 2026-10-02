"""Small part-building helpers shared by the garage and car generators.

Positions are world (Plot1) coordinates. Orientation matrices are written
row by row (world axes), their columns are the part's local X, Y, Z axes.
A Cylinder's axis is its local X; a WedgePart's slope runs from its tall
back edge (+Z) down to its front (-Z).
"""

import math

IDENTITY = [[1, 0, 0], [0, 1, 0], [0, 0, 1]]


def r(x):
    x = round(x, 3)
    return int(x) if x == int(x) else x


def r6(x):
    x = round(x, 6)
    return int(x) if x == int(x) else x


def rot_x(deg):
    c, s = math.cos(math.radians(deg)), math.sin(math.radians(deg))
    return [[1, 0, 0], [0, c, -s], [0, s, c]]


def rot_y(deg):
    c, s = math.cos(math.radians(deg)), math.sin(math.radians(deg))
    return [[c, 0, s], [0, 1, 0], [-s, 0, c]]


def rot_z(deg):
    c, s = math.cos(math.radians(deg)), math.sin(math.radians(deg))
    return [[c, -s, 0], [s, c, 0], [0, 0, 1]]


UPRIGHT = rot_z(90)  # a Cylinder's axis pointing up
ALONG_Z = rot_y(90)  # a Cylinder's axis pointing along Z
TURN_180 = rot_y(180)  # a WedgePart whose tall end faces -Z


def add(a, b):
    return tuple(x + y for x, y in zip(a, b))


def sub(a, b):
    return tuple(x - y for x, y in zip(a, b))


def scale(a, s):
    return tuple(x * s for x in a)


def dot(a, b):
    return sum(x * y for x, y in zip(a, b))


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def unit(a):
    return scale(a, 1 / dot(a, a) ** 0.5)


def columns(x, y, z):
    """Rotation matrix whose local X/Y/Z axes point along x, y, z."""
    return [[x[i], y[i], z[i]] for i in range(3)]


class Parts:
    """Collects the parts of one model."""

    def __init__(self, name):
        self.name = name
        self.parts = []

    def part(self, name, size, pos, color, material="SmoothPlastic", rot=None, shape=None,
             collide=False, kind="Part", children=None):
        """Every part is Anchored and never fires Touched. Only `collide`
        parts block players and raycasts; the rest are looks only."""
        props = {
            "Size": [r(s) for s in size],
            "CFrame": {"CFrame": {"position": [r(c) for c in pos],
                                  "orientation": [[r6(v) for v in row] for row in (rot or IDENTITY)]}},
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
        node = {"name": name, "className": kind, "properties": props}
        if children:
            node["children"] = children
        self.parts.append(node)
        return node

    def box(self, name, lo, hi, color, material="SmoothPlastic", **kw):
        """An axis-aligned box from corner `lo` to corner `hi`."""
        size = tuple(abs(b - a) for a, b in zip(lo, hi))
        return self.part(name, size, scale(add(lo, hi), 0.5), color, material, **kw)

    def ball(self, name, d, pos, color, material="SmoothPlastic", **kw):
        return self.part(name, (d, d, d), pos, color, material, shape="Ball", **kw)

    def cyl(self, name, length, d, pos, color, material="SmoothPlastic", rot=UPRIGHT, **kw):
        """A cylinder `length` long along `rot`'s X (upright by default)."""
        return self.part(name, (length, d, d), pos, color, material, shape="Cylinder", rot=rot, **kw)

    def wedge(self, name, size, pos, color, material="SmoothPlastic", rot=None, **kw):
        return self.part(name, size, pos, color, material, rot=rot, kind="WedgePart", **kw)

    def beam(self, name, a, b, width, height, color, material="SmoothPlastic", up=(0, 1, 0), **kw):
        """A box from point a to point b (its local Z), `height` along the
        side of `up` that is square to the beam."""
        d = sub(b, a)
        z = unit(d)
        x = unit(cross(up, z))
        y = cross(z, x)
        length = dot(d, d) ** 0.5
        return self.part(name, (width, height, length), scale(add(a, b), 0.5), color, material,
                         rot=columns(x, y, z), **kw)

    def slab(self, name, a, b, depth, thickness, color, material="SmoothPlastic", **kw):
        """A flat board along Z (`depth` long) whose top edge-on profile runs
        from a to b in the X/Y plane; the board lies on top of that line."""
        d = (b[0] - a[0], b[1] - a[1], 0)
        x = unit(d)
        y = (-x[1], x[0], 0)  # up-facing normal
        length = dot(d, d) ** 0.5
        center = add(scale(add(a, b), 0.5), scale(y, thickness / 2))
        return self.part(name, (length, thickness, depth), center, color, material,
                         rot=columns(x, y, (0, 0, 1)), **kw)

    def model(self):
        return {"name": self.name, "className": "Model", "children": self.parts}
