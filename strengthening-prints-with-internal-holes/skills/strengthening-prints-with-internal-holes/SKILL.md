---
name: strengthening-prints-with-internal-holes
description: Use when a 3D-printed part (FDM, any slicer, often modelled in OpenSCAD) needs to be stronger in specific areas such as joints, forks, hinge tongues, bolt bosses or clamps, without raising infill or changing the slicer profile, or when someone mentions adding internal holes, voids or "arbitrary walls" to force extra perimeters.
---

# Strengthening prints with internal holes

## Overview

The slicer lays perimeters round every hole in a layer. Put small hidden
holes inside a weak area and each one gets its own perimeter loops. Packed
close together, those loops fuse into solid posts, so the area prints nearly
solid while the rest of the part keeps normal infill. The outside of the part
doesn't change.

## The recipe (proven values)

| Rule | Value | Why |
|---|---|---|
| Hole direction | **Vertical in the print orientation** (along the printer's Z) | Perimeters only form round holes that cut through the layers. A hole lying horizontal gets no perimeters, only bridges. |
| Hole diameter | **1 mm** | 0.1 mm gets closed by the slicer's slice closing radius (PrusaSlicer/Orca/SuperSlicer default 0.049 mm). Big holes just remove plastic. |
| Spacing | **4 mm** centre to centre | Leaves 3 mm between holes: about 3–4 perimeters from each side meet. |
| Side clearance | **≥ 1 mm** from every side wall and every cavity (bolt holes, nut pockets, insert pockets, slots) | Keeps the holes from merging with the surface or a cavity. |
| Top/bottom clearance | **0.5 mm** from the top and bottom faces | Ends the hole inside the part. Much less (e.g. 0.1 mm, under one layer) and the slicer may open it through the face. |
| Slicer | **At least 4 perimeters**, about 0.45 mm lines | So the loops from neighbouring holes meet in the middle. |

If the profile has fewer perimeters, tighten the spacing instead:
spacing ≈ hole diameter + 2 × perimeters × line width. For 3 perimeters of 0.45 mm
that's about 3.5 mm.

The holes must never break the surface. Each one is a closed void inside the part.

## OpenSCAD implementation

Apply the holes to the part *in its print orientation*. Clip the hole grid to
a copy of the part shrunk by the clearances. That trims holes automatically
near every surface and cavity, so you never place them by hand:

```openscad
rib_d = 1; rib_pitch = 4; rib_wall = 1; rib_cap = 0.5;

// Shrink a part by rib_wall sideways and rib_cap vertically: intersect it with
// copies shifted to the corners, edges and faces of that box. Cavities grow by
// the same amount, because they move with each copy.
module rib_eroded()
    intersection_for (o = [for (x=[-1:1], y=[-1:1], z=[-1:1]) [x*rib_wall, y*rib_wall, z*rib_cap]])
        translate(o) children();

// vertical hole grid over a region; aligned to 0 so it lines up with pivots
module rib_grid(x0, x1, y0, y1)
    for (x=[ceil(x0/rib_pitch)*rib_pitch : rib_pitch : x1],
         y=[ceil(y0/rib_pitch)*rib_pitch : rib_pitch : y1])
        translate([x, y, -1]) cylinder(d=rib_d, h=500, $fn=12);

// part_in_print_orientation() = your part, already rotated and placed on z=0
difference() {
    part_in_print_orientation();
    intersection() {
        rib_grid(-20, 20, -20, 20);              // limit to the weak areas
        rib_eroded() part_in_print_orientation();
    }
}
```

Keep the holes in the print exports only. Assembly and collision views don't
need them.

## Verify the STL

Every internal hole is its own closed shell inside the part. A hole that
breaks the surface merges into the outer skin and changes its area. Export
the same part without holes **from the same model version**, then run:

```bash
python3 scripts/check_internal_holes.py plain.stl strengthened.stl
```

The script lives in this skill's directory. It passes (exit 0) when the outer
skin area is unchanged, and it reports the hole count and any slivers. A stale
plain export (one made before another edit) shows up as a false "CHANGED".
In the slicer's layer preview, look for the extra perimeter rings round the holes.

## Common mistakes

- **Holes horizontal on the bed, e.g. parallel to a horizontal bolt hole.** They get no perimeters. Choose the direction by the print orientation, not by the part's own geometry.
- **Through-holes or open slots.** These change the part's outside surface. Keep the holes as closed internal voids.
- **Holes that are too small.** The slicer closes them silently, so check the layer preview.
- **Too few perimeters in the profile.** You get rings with infill between them, not solid posts.
- **A grid that misses a thin wall.** A grid lined up on a fixed origin can fall entirely in a wall's clearance zone. Check the hole count per region. If a wall (for example a 7 mm fork ear) gets none, run a row down its midline.
- **Checking only that the STL is manifold.** That says nothing about whether the holes are internal. Use the shell check above.
