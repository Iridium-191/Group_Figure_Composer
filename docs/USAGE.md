# Usage Guide

## Interactive workflow

Start the app:

```matlab
addpath(genpath(pwd))
GroupFigureComposer
```

A typical workflow is:

1. Create the layout: set row count, column count, canvas width, canvas height, panel gap, and page margin.
2. Merge panels if a large panel should span several cells.
3. Import source files into each panel. Supported inputs are `.fig`, `.svg`, `.png`, `.jpg`, `.jpeg`, `.tif`, `.tiff`, and `.bmp`.
4. Apply a unified font and font size.
5. Refine panel labels, object colors, legends, line styles, map colormaps, highlights, and scale bars.
6. Drag panels, axes, labels, and annotations to finalize the layout.
7. Preview the figure.
8. Export the final figure or save a `.gfc.mat` project file.

## Layout

The app uses a fixed pixel canvas. This makes the preview and export geometry predictable. The panel frames visible during editing are layout aids only; they are not drawn in the exported figure.

Panel layout controls include:

- row count and column count;
- canvas width and height in pixels;
- panel gap;
- page margin;
- rectangular panel merge and unmerge.

## Importing files

Each empty panel has a `+` button. You can also use the import tab to import into the selected panel.

Supported input formats:

- MATLAB `.fig` files;
- SVG files;
- raster images: `.png`, `.jpg`, `.jpeg`, `.tif`, `.tiff`, `.bmp`.

MATLAB `.fig` import copies common axes children and axes-level styling. SVG import parses common primitives such as lines, rectangles, circles, ellipses, polygons, simple paths, and text. Raster import displays the image and can crop white margins.

## Object editing

The right-side object tree lists editable objects in the selected canvas. Selecting an object exposes common properties in the property table. You can also select objects directly on the canvas.

Supported direct manipulation includes:

- moving and resizing panels;
- moving and resizing axes regions;
- moving panel labels;
- moving titles, axes labels, text, rectangles, scale-bar lines, and scale-bar text;
- deleting selected objects with Delete or Backspace.

## Color and style

The app includes built-in palettes such as Okabe-Ito, Nature Muted, Science Bright, Tableau 10, ColorBrewer-like palettes, and scientific colormaps including Viridis, Cividis, Magma, Inferno, and Plasma.

You can:

- apply a palette to all line objects;
- apply a swatch color to a selected line, scatter, text, rectangle, or scale bar;
- import a palette image and extract representative colors;
- apply or reverse a map colormap;
- set `CLim` manually for map panels;
- edit a three-control-point custom colormap.

## Export

Supported output formats:

- `.png`
- `.tif` / `.tiff`
- `.pdf`
- `.svg`
- `.fig`

The preview window and export use the same rendering pathway, so the preview should match the exported geometry.

## Data export

The app can export data from assembled panels to a `.mat` file. The exported variable is named `groupData`. Data fields use safe MATLAB field names based on display names when available. For example:

```matlab
groupData.fig1.curveA.x
groupData.fig1.curveA.y
groupData.fig1.legend_001.name
```

## Project files

Use `Save Project` / `保存工程` to save a `.gfc.mat` project. The project stores layout settings, panel positions, axes positions, label positions, style settings, and snapshots of imported content when possible.

Use `Open Project` / `打开工程` to continue editing.

## Scriptable workflow

For reproducible or batch composition, use `GroupFigureComposerLite`:

```matlab
addpath(genpath(pwd))

files = ["panel_a.fig", "panel_b.fig", "panel_c.png"];
result = GroupFigureComposerLite(files, 'composite.pdf', ...
    Rows=1, Cols=3, ...
    WidthPx=1800, HeightPx=650, ...
    DPI=300, ...
    FontName='Arial', FontSize=9, ...
    Visible='off');
```

Arguments:

| Option | Meaning | Default |
|---|---|---|
| `Rows` | Number of panel rows | auto |
| `Cols` | Number of panel columns | auto |
| `WidthPx` | Output canvas width in pixels | `1200` |
| `HeightPx` | Output canvas height in pixels | `900` |
| `DPI` | Export resolution | `300` |
| `FontName` | Unified font name | `Arial` |
| `FontSize` | Unified font size | `9` |
| `Visible` | Figure visibility | `off` |

If `outputFile` is empty, the function returns a rendered figure without exporting.
