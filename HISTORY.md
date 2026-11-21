# History

Plain-language timeline of what was done and when.

- **2026-11-21** - Started the repo as a Claude Code plugin marketplace for selected skills.
  First skill: strengthening 3D prints with internal holes, so the slicer adds extra
  perimeters in weak areas without raising infill.
- **2026-11-21** - Added the story of where the internal-holes trick came from (found by
  accident) and the case for it being a slicer feature, to the skill's README.
- **2026-11-21** - Added the part render and before/after slicer previews to the internal-holes
  skill's README, cropped and scaled to match, with metadata stripped.
- **2026-11-21** - Swapped the README screenshots for matching renders made from the model with
  one camera (the part, and a simulated layer without and with holes).
- **2026-11-21** - Added a section on using the internal-holes trick with other CAD programs:
  post-processing any exported STL (tested), building it in Fusion 360-style CAD or FreeCAD,
  or adding negative volumes in the slicer.
- **2026-11-21** - The skill now works beyond OpenSCAD: a tested FreeCAD script (on a live
  model, STEP or STL) and a route for any CAD program through an exported STL. Native Fusion 360
  is noted as possible but untested. Commits now use UTC timestamps.
