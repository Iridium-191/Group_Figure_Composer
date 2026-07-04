# Changelog

All notable changes to this project should be documented in this file.

This project uses a simple `MAJOR.MINOR.PATCH` version style:

- `MAJOR`: incompatible project-file or API changes;
- `MINOR`: new features that remain backward compatible;
- `PATCH`: bug fixes and documentation updates.

## [0.1.0] - 2026-07-04

### Added

- Initial public MATLAB implementation.
- Interactive `GroupFigureComposer` GUI.
- Scriptable `GroupFigureComposerLite` entry point.
- Fixed-pixel multi-panel canvas.
- Panel merge/unmerge support.
- FIG, SVG, and raster-image import.
- Unified font and line-style controls.
- Palette-based recoloring and map colormap controls.
- Direct canvas dragging for panels, axes, labels, text, rectangles, highlights, and scale bars.
- Preview and export through a shared rendering pathway.
- Export to PNG, TIF/TIFF, PDF, SVG, and FIG.
- Data export to `groupData` MAT files.
- `.gfc.mat` project save/open workflow.
- MATLAB unit tests for core layout, rendering, export, and data extraction behavior.
