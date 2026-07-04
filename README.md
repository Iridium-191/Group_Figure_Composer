# Group Figure Composer

Group Figure Composer is a MATLAB utility for assembling publication-style multi-panel figures from MATLAB `.fig` files, SVG files, and raster images. It provides both an interactive GUI and a scriptable lightweight entry point for reproducible figure composition.

中文说明见 [README.zh-CN.md](README.zh-CN.md)。

## Main entry points

Interactive app:

```matlab
addpath(genpath(pwd))
GroupFigureComposer
```

Scriptable lightweight composer:

```matlab
addpath(genpath(pwd))

files = ["panel_a.fig", "panel_b.svg", "panel_c.png"];
GroupFigureComposerLite(files, 'composite.png', ...
    Rows=1, Cols=3, WidthPx=1800, HeightPx=650, DPI=300);
```

A minimal runnable example is provided in [`examples/demo_lite.m`](examples/demo_lite.m):

```matlab
run("examples/demo_lite.m")
```

## What it does

Group Figure Composer is designed for the common final-stage figure assembly workflow in MATLAB-based research:

- create fixed-size multi-panel canvases using pixel width and height;
- merge and unmerge rectangular panel regions;
- import MATLAB `.fig`, `.svg`, `.png`, `.jpg`, `.jpeg`, `.tif`, `.tiff`, and `.bmp` files;
- preserve common axes, labels, legends, colorbars, and line objects from imported figures;
- adjust panel labels, fonts, line widths, colors, legends, map colormaps, text, highlights, and scale bars;
- drag panels, axes, labels, text, rectangles, and scale bars directly on the canvas;
- use snap guides to align panels, axes, labels, and graphic annotations;
- preview the final figure with the same renderer used for export;
- export `.png`, `.tif/.tiff`, `.pdf`, `.svg`, and `.fig` files;
- export line/scatter/image data from assembled panels to a MATLAB `.mat` file;
- save and reopen `.gfc.mat` project files for continued editing.

## Requirements

Recommended environment:

- MATLAB R2024b or newer.
- Inkscape is optional. It is used only as a fallback for complex SVG files that cannot be parsed directly.

Feature-specific notes:

- Raster import uses MATLAB image I/O functions.
- Palette extraction from an image uses `kmeans`; this may require the Statistics and Machine Learning Toolbox depending on your MATLAB installation.
- The interactive GUI uses `uifigure` and related MATLAB UI components.

Earlier MATLAB releases may work for parts of the code, but they have not been treated as the reference environment.

## Installation

Clone or download this repository, then add the repository to the MATLAB path:

```matlab
addpath(genpath("/path/to/GroupFigureComposer"))
savepath   % optional
```

No build step is required.

## Repository layout

```text
GroupFigureComposer.m                   Interactive GUI launcher
GroupFigureComposerApp.m                Main interactive app implementation
GroupFigureComposerLite.m               Scriptable command-style composer
GroupFigureComposer_appdesigner_import.m App Designer wrapper entry point
+gfc/                                    Reusable core functions
examples/                               Minimal examples
tests/                                  MATLAB unit tests
docs/                                   Usage and API documentation
```

## Testing

From the repository root:

```matlab
addpath(genpath(pwd))
results = runtests("tests");
assertSuccess(results)
```

The tests cover panel labels, panel merge/unmerge logic, raster cropping, data extraction, rendering geometry, font propagation, and basic export behavior.

## Documentation

- [Installation notes](INSTALL.md)
- [Usage guide](docs/USAGE.md)
- [Chinese usage guide](docs/USAGE.zh-CN.md)
- [Core API overview](docs/API.md)
- [Contributing guide](CONTRIBUTING.md)
- [Changelog](CHANGELOG.md)

## Author

Ruilin Mao, ICQM, Peking University.

## Known limitations

- The repository does not generate a native `.mlapp` file automatically. MATLAB does not provide a stable public API for creating App Designer `.mlapp` packages from scripts. If a native `.mlapp` wrapper is required, create a blank App Designer app and call `GroupFigureComposer_appdesigner_import` from its `StartupFcn`.
- Direct SVG parsing supports common vector primitives. Complex SVG elements such as masks, filters, embedded images, gradients, and clipping may require Inkscape fallback or raster import.
- The GUI is currently written mainly for Chinese-language local use. `GroupFigureComposerLite` is the simpler English/scriptable entry point.

## Citing

If this tool helps prepare figures for a publication or preprint, cite the repository using the metadata in [`CITATION.cff`](CITATION.cff). After creating the GitHub repository, update only the `repository-code` field to the final repository URL.

## License

This project is released under the MIT License. See [LICENSE](LICENSE).
