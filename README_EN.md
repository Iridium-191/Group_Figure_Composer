# Group Figure Composer

MATLAB toolkit for composing publication-style multi-panel scientific figures.

Author: **Ruilin Mao**, **ICQM, Peking University**

License: **MIT**

## Overview

Group Figure Composer helps assemble MATLAB `.fig` files, SVG graphics, and
raster images into a single multi-panel figure. The repository includes:

- a full Chinese interactive GUI for detailed manual composition;
- an English command-style utility for lightweight, scriptable figure assembly;
- reusable core functions under the `+gfc` package;
- unit tests and examples suitable for GitHub distribution.

The tool is designed around fixed pixel canvas geometry. Preview and export use
the same render path, so panel spacing, label position, axes frame size, font
size, legend content, and colormap settings remain consistent.

## Installation

Clone or download the repository, then add it to the MATLAB path:

```matlab
addpath(genpath(pwd))
```

MATLAB R2024b or newer is recommended.

Inkscape is optional. If installed and discoverable from the system path, it can
be used as a fallback renderer for complex SVG files that cannot be parsed as
editable MATLAB primitives.

## Entry Points

### Chinese interactive GUI

```matlab
GroupFigureComposer
```

or explicitly:

```matlab
GroupFigureComposerCN
```

### English interactive GUI

```matlab
GroupFigureComposerGUI_EN
```

You can also launch the English GUI by calling `GroupFigureComposerEN` without
input arguments:

```matlab
GroupFigureComposerEN
```

### English command-style utility

```matlab
files = ["panel_a.fig", "panel_b.svg", "panel_c.png"];
GroupFigureComposerEN(files, "composite.png", ...
    Rows=1, Cols=3, WidthPx=1800, HeightPx=650, DPI=300);
```

Equivalent lower-level utility:

```matlab
GroupFigureComposerLite(files, "composite.png", ...
    Rows=1, Cols=3, WidthPx=1800, HeightPx=650, DPI=300);
```

Run the bundled demo:

```matlab
run("examples/demo_lite.m")
```

## Supported Inputs

- MATLAB figures: `.fig`
- SVG: `.svg`
- Raster images: `.png`, `.jpg`, `.jpeg`, `.tif`, `.tiff`, `.bmp`

Raster imports can be automatically cropped to remove white margins. SVG import
parses common shapes and text; complex SVG files may be rasterized through
Inkscape when available.

## Supported Outputs

The export layer supports:

- `.fig`
- `.svg`
- `.png`
- `.tif` / `.tiff`
- `.pdf`

The interactive GUI also exports data to a `.mat` file as `groupData`.

## Interactive GUI Workflow

1. **Layout**
   - Set the canvas width and height in pixels.
   - Choose panel rows and columns.
   - Merge or unmerge rectangular grid regions.
   - Adjust panel spacing and page margin.
   - Move or resize panels directly on the canvas.

2. **Import**
   - Use the per-panel `+` button or the import button to add a `.fig`, `.svg`,
     or raster image.
   - Imported content is resized to fit the selected panel.
   - Apply unified font, font size, axes line width, and tick direction.
   - Use automatic plot-frame alignment to align the outer plot frames across
     adjacent rows and columns, including merged panels.

3. **Refine**
   - Select panels, axes, or graphics objects from the canvas or object tree.
   - Edit common properties such as color, line width, line style, marker style,
     title, labels, colormap, and `CLim`.
   - Recolor objects with palette swatches instead of manually typing RGB values.
   - Create custom control-point colormaps with editable color-axis positions
     and interpolation count.
   - Add legends with explicit object selection.
   - Add text, highlights, rectangles, scale bars, and other simple annotations.
   - Drag text/annotation objects and use snap guides for alignment.

4. **Preview and Export**
   - Open a separate preview window.
   - Export figures and data.
   - Save/load project files to continue editing later.

## Data Export

The GUI can export a `.mat` file containing `groupData`. Extractable graphics
objects are organized by panel/figure, for example:

```matlab
groupData.fig1.curveA.x
groupData.fig1.curveA.y
groupData.fig1.legend_001.name
groupData.fig1.legend_001.panelLabel
```

The export also includes `groupData.panelMap`, source file metadata, panel
labels, and import reports. Unsupported or partially extractable objects keep
their source path and object type information for traceability.

## Repository Layout

```text
GroupFigureComposer.m          Main Chinese GUI launcher
GroupFigureComposerCN.m        Explicit Chinese GUI launcher
GroupFigureComposerGUI_EN.m    English interactive GUI launcher
GroupFigureComposerEN.m        English GUI / command-style launcher
GroupFigureComposerLite.m      English lightweight composition utility
GroupFigureComposerApp.m       Main interactive app implementation
+gfc/                         Core reusable functions
examples/                     Minimal examples
tests/                        MATLAB unit tests
README.md                     Bilingual overview
README_EN.md                  English documentation
README_ZH.md                  Chinese documentation
LICENSE                       MIT License
```

## Tests

```matlab
addpath(genpath(pwd))
results = runtests("tests");
assertSuccess(results)
```

The test suite covers panel layout, merging, raster cropping, SVG import,
legend preservation, font synchronization, colormap handling, plot-frame
alignment including merged panels, data export, and rendering/export basics.

## Notes on `.mlapp`

The current implementation is a programmatic `uifigure` app rather than a
binary `.mlapp` file. MATLAB does not provide a stable public API for generating
fully editable `.mlapp` files from scripts. Keeping the GUI in `.m` files makes
the project easier to version-control, test, and distribute on GitHub.

## Citation / Authorship

If this tool is useful in your workflow, please cite or acknowledge:

**Ruilin Mao, ICQM, Peking University. Group Figure Composer. MIT License.**
