#!/usr/bin/env bash
# Builds a test block from the OpenSCAD snippet in SKILL.md, then checks that
# check_internal_holes.py passes the strengthened block and fails a block whose
# holes go straight through. Needs openscad and python3.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
skill="$here/../skills/strengthening-prints-with-internal-holes"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
command -v openscad >/dev/null || { echo "skip: openscad not installed"; exit 0; }

# test part: a block with a horizontal M4 hole, already in print orientation
cat > "$tmp/part.scad" <<'SCAD'
module part_in_print_orientation() difference() {
    cube([30, 16, 10]);
    translate([8, -1, 5]) rotate([-90, 0, 0]) cylinder(d=4.4, h=20, $fn=32);
}
SCAD
# the snippet exactly as published, plus switches for the plain and broken variants
{ echo 'mode = "strong";'; cat "$tmp/part.scad"
  python3 -I -c 'import re,sys; print(re.search(r"```openscad\n(.*?)```", open(sys.argv[1]).read(), re.S).group(1))' "$skill/SKILL.md" \
    | sed 's/^difference() {$/if (mode == "strong") difference() {/'
  echo 'if (mode == "plain") part_in_print_orientation();'
  echo 'if (mode == "broken") difference() { part_in_print_orientation(); rib_grid(2, 28, 2, 14); }'
} > "$tmp/test.scad"

for m in strong plain broken; do
  openscad --backend=manifold -D "mode=\"$m\"" -o "$tmp/$m.stl" "$tmp/test.scad" >/dev/null 2>&1
done
check="$skill/scripts/check_internal_holes.py"
python3 -I "$check" "$tmp/plain.stl" "$tmp/strong.stl"
if python3 -I "$check" "$tmp/plain.stl" "$tmp/broken.stl" >/dev/null; then
  echo "FAIL: checker passed holes that break the surface"; exit 1
fi
echo "ok: snippet builds internal holes, checker passes them and fails through-holes"

# FreeCAD builder: make a part in FreeCAD, save it as STEP, strengthen it, check it
if command -v freecadcmd >/dev/null; then
  cat > "$tmp/make_part.py" <<PY
import FreeCAD, Part
b = Part.makeBox(30, 16, 10)
hole = Part.makeCylinder(2.2, 20, FreeCAD.Vector(8, -2, 5), FreeCAD.Vector(0, 1, 0))
b.cut(hole).exportStep("$tmp/part.step")
PY
  freecadcmd -c "exec(open('$tmp/make_part.py').read())" >/dev/null 2>&1
  freecadcmd -c "import sys; sys.argv=['x', '$tmp/part.step', '$tmp/fc']; exec(open('$skill/scripts/strengthen_freecad.py').read())" >/dev/null 2>&1
  python3 -I "$check" "$tmp/fc_plain.stl" "$tmp/fc_strengthened.stl"
  echo "ok: FreeCAD builder makes internal holes the checker passes"
else
  echo "skip: freecadcmd not installed, FreeCAD builder not tested"
fi
