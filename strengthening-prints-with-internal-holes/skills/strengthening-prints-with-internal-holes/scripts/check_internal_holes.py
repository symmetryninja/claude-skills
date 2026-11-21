#!/usr/bin/env python3
"""Check that strengthening holes in an STL are all internal.

Usage: python3 check_internal_holes.py PLAIN.stl STRENGTHENED.stl

PLAIN is the same part exported without the holes. Every fully internal hole
is its own closed shell inside the part; a hole that breaks the surface merges
into the outer skin instead. So: the outer skin area must match the plain part,
and the extra shells are the holes. Exits 1 if the outer skin changed.
No dependencies beyond the standard library; reads ASCII or binary STL.
"""
import math
import struct
import sys


def triangles(path):
    data = open(path, "rb").read()
    if data[:5] == b"solid" and b"facet" in data[:300]:
        verts = [tuple(map(float, line.split()[1:4]))
                 for line in data.decode().splitlines() if line.strip().startswith("vertex")]
        return [verts[i:i + 3] for i in range(0, len(verts), 3)]
    count = struct.unpack("<I", data[80:84])[0]
    out = []
    for i in range(count):
        f = struct.unpack("<12f", data[84 + i * 50:84 + i * 50 + 48])
        out.append([f[3:6], f[6:9], f[9:12]])
    return out


def shell_areas(tris):
    """Group triangles into connected shells (shared vertices); return areas, largest first."""
    parent = list(range(len(tris)))

    def find(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i

    owner = {}
    for i, tri in enumerate(tris):
        for v in tri:
            key = tuple(round(c, 4) for c in v)
            if key in owner:
                parent[find(i)] = find(owner[key])
            else:
                owner[key] = i
    areas = {}
    for i, (p, q, r) in enumerate(tris):
        u = [q[k] - p[k] for k in range(3)]
        w = [r[k] - p[k] for k in range(3)]
        a = 0.5 * math.sqrt((u[1] * w[2] - u[2] * w[1]) ** 2 + (u[2] * w[0] - u[0] * w[2]) ** 2
                            + (u[0] * w[1] - u[1] * w[0]) ** 2)
        root = find(i)
        areas[root] = areas.get(root, 0) + a
    return sorted(areas.values(), reverse=True)


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    plain, strong = shell_areas(triangles(sys.argv[1])), shell_areas(triangles(sys.argv[2]))
    holes = strong[1:]
    same = abs(plain[0] - strong[0]) < 0.5
    slivers = [a for a in holes if a < 4]
    print(f"outer skin {plain[0]:.1f} -> {strong[0]:.1f} mm2 ({'unchanged' if same else 'CHANGED: a hole breaks the surface'})")
    print(f"internal holes: {len(holes) - (len(plain) - 1)}, slivers under 4 mm2: {len(slivers)}")
    sys.exit(0 if same else 1)


if __name__ == "__main__":
    main()
