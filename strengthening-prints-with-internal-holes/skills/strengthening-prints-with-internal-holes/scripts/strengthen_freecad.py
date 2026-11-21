"""Add internal strengthening holes to a solid in FreeCAD.

Same method as the OpenSCAD snippet in SKILL.md: a grid of vertical holes,
clipped to the part shrunk by `wall` sideways and `cap` vertically (the part
intersected with copies of itself shifted to the corners, edges and faces of
that box), then cut from the part. The shape must already be in its print
orientation (Z up).

In FreeCAD's Python console, a macro, or over an MCP connection:
    exec(open("/path/to/strengthen_freecad.py").read())
    obj.Shape = add_strengthening_holes(obj.Shape)

From a shell (STEP, BREP, IGES or STL in; writes plain and strengthened STLs
for check_internal_holes.py):
    freecadcmd -c "import sys; sys.argv=['x', 'in.step', 'out']; exec(open('strengthen_freecad.py').read())"
"""
import itertools
import sys

import FreeCAD
import Part


def add_strengthening_holes(shape, d=1.0, pitch=4.0, wall=1.0, cap=0.5, region=None):
    """Return `shape` with internal vertical holes. `region` limits the grid to
    (xmin, xmax, ymin, ymax); the default covers the whole part."""
    bb = shape.BoundBox
    x0, x1, y0, y1 = region or (bb.XMin, bb.XMax, bb.YMin, bb.YMax)

    eroded = shape
    for i, j, k in itertools.product((-1, 0, 1), repeat=3):
        if (i, j, k) != (0, 0, 0):
            eroded = eroded.common(shape.translated(FreeCAD.Vector(i * wall, j * wall, k * cap)))

    h = bb.ZLength + 2
    cols = []
    x = pitch * -(-x0 // pitch)          # grid aligned to 0, like the OpenSCAD version
    while x <= x1:
        y = pitch * -(-y0 // pitch)
        while y <= y1:
            cols.append(Part.makeCylinder(d / 2, h, FreeCAD.Vector(x, y, bb.ZMin - 1)))
            y += pitch
        x += pitch
    if not cols:
        return shape
    holes = Part.makeCompound(cols).common(eroded)
    return shape.cut(holes)


def _load(path):
    if path.lower().endswith(".stl"):
        import Mesh
        mesh = Mesh.Mesh(path)
        shell = Part.Shape()
        shell.makeShapeFromMesh(mesh.Topology, 0.05)
        return Part.makeSolid(shell).removeSplitter()
    return Part.read(path)


if len(sys.argv) >= 3 and sys.argv[1] != "-c":
    src, out = sys.argv[1], sys.argv[2]
    part = _load(src)
    strong = add_strengthening_holes(part)
    part.exportStl(out + "_plain.stl")
    strong.exportStl(out + "_strengthened.stl")
    print(f"wrote {out}_plain.stl and {out}_strengthened.stl")
