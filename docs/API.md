# Core API Overview

This document summarizes the public-facing functions that are most likely to be reused outside the GUI. Internal helper functions may change without notice.

## Launchers

### `GroupFigureComposer`

Launch the interactive GUI.

```matlab
GroupFigureComposer
```

Returns the app object when called with an output argument:

```matlab
app = GroupFigureComposer;
```

### `GroupFigureComposerLite`

Compose a set of input files into a grid and optionally export the result.

```matlab
result = GroupFigureComposerLite(files, outputFile, Name=Value)
```

Inputs:

- `files`: string array or cell-compatible list of `.fig`, `.svg`, or raster image paths.
- `outputFile`: output filename. Use an empty string to skip export.

Name-value options:

| Option | Description | Default |
|---|---|---|
| `Rows` | Number of rows | auto |
| `Cols` | Number of columns | auto |
| `WidthPx` | Canvas width in pixels | `1200` |
| `HeightPx` | Canvas height in pixels | `900` |
| `DPI` | Export resolution | `300` |
| `FontName` | Unified font | `Arial` |
| `FontSize` | Unified font size | `9` |
| `Visible` | Figure visibility | `off` |

Returned fields:

- `figure`: rendered MATLAB figure handle;
- `reports`: import reports for each input file;
- `rows`: resolved row count;
- `cols`: resolved column count.

## Layout functions

### `gfc.createPanels`

Create a rectangular panel structure array.

```matlab
panels = gfc.createPanels(rows, cols)
```

### `gfc.mergePanels`

Merge a rectangular region of panels.

```matlab
[panels, mergedPanel] = gfc.mergePanels(panels, row, col, rowSpan, colSpan)
```

### `gfc.unmergePanel`

Split a merged panel back into its covered cells.

```matlab
panels = gfc.unmergePanel(panels, panelId)
```

### `gfc.panelPositions`

Compute normalized panel positions from layout settings.

```matlab
positions = gfc.panelPositions(panels, rows, cols, gap, margin)
```

## Import functions

### `gfc.importFigToAxes`

Import the main axes content from a MATLAB `.fig` file into an existing axes.

```matlab
report = gfc.importFigToAxes(ax, filename)
```

### `gfc.importSvgToAxes`

Parse common SVG elements into an existing axes. Optionally use Inkscape fallback.

```matlab
report = gfc.importSvgToAxes(ax, filename, AllowInkscapeFallback=true)
```

### `gfc.importRasterToAxes`

Read and display a raster image in an existing axes.

```matlab
report = gfc.importRasterToAxes(ax, filename, AutoCrop=true)
```

### `gfc.cropRaster`

Crop white margins from a raster image.

```matlab
[cropped, rect, mask] = gfc.cropRaster(img, Padding=2, Threshold=250)
```

## Styling functions

### `gfc.styleAxes`

Apply unified font, font size, axes line width, tick direction, and child line width settings.

```matlab
gfc.styleAxes(axesList, FontName='Arial', FontSize=9, LineWidth=1)
```

### `gfc.builtinPalettes`

Return an RGB palette or colormap.

```matlab
palette = gfc.builtinPalettes('Okabe-Ito', 8)
```

### `gfc.applyPalette`

Apply a palette to a selected object, panel, figure, or axes target.

```matlab
changed = gfc.applyPalette(target, palette, 'lines')
```

### `gfc.applyObjectColor`

Apply an RGB color to the most relevant color property of an object.

```matlab
changed = gfc.applyObjectColor(h, [0.1 0.2 0.8])
```

### `gfc.applyLineStyle`

Apply line style and width to a set of handles.

```matlab
changed = gfc.applyLineStyle(handles, LineStyle="--", LineWidth=1.2)
```

### `gfc.controlPointColormap`

Create a colormap from RGB control points and normalized positions.

```matlab
cmap = gfc.controlPointColormap(colors, positions, 256)
```

## Annotation functions

### `gfc.addHighlight`

Add a point highlight to an axes.

```matlab
h = gfc.addHighlight(ax, x, y)
```

### `gfc.addScalebar`

Add a scale bar and label to an axes.

```matlab
h = gfc.addScalebar(ax, lengthValue, '1 µm')
```

### `gfc.addStyledLegend`

Create a styled legend from selected display-name objects.

```matlab
lgd = gfc.addStyledLegend(ax)
```

## Rendering and export

### `gfc.renderCompositeFigure`

Render panel axes into a final export figure.

```matlab
fig = gfc.renderCompositeFigure(panels, axesList, Rows=2, Cols=2, WidthPx=1200, HeightPx=900)
```

### `gfc.exportComposite`

Export a rendered figure.

```matlab
gfc.exportComposite(fig, 'composite.png', DPI=300)
```

Supported extensions are `.fig`, `.png`, `.tif`, `.tiff`, `.pdf`, and `.svg`.

### `gfc.extractGroupData`

Extract data from assembled axes into a structured MATLAB variable.

```matlab
groupData = gfc.extractGroupData(axesList, panels, assetInfos, ProjectName='demo')
```
