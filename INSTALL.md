# Installation

## 1. Get the code

Clone the repository or download it as a ZIP file.

```bash
git clone https://github.com/<OWNER>/<REPO>.git
```

Replace `<OWNER>/<REPO>` with the final GitHub repository path after the repository is created.

## 2. Add the repository to MATLAB path

In MATLAB, run from any location:

```matlab
addpath(genpath("/path/to/GroupFigureComposer"))
```

To keep the path for future MATLAB sessions:

```matlab
savepath
```

Alternatively, start MATLAB from the repository root and run:

```matlab
addpath(genpath(pwd))
```

## 3. Start the GUI

```matlab
GroupFigureComposer
```

## 4. Use the command-style composer

```matlab
files = ['a.fig', 'b.svg', 'c.png'];
GroupFigureComposerLite(files, 'composite.png', Rows=1, Cols=3);
```

## Optional: install Inkscape

Inkscape is not required for normal MATLAB `.fig` or raster-image workflows. It is used only as a fallback when complex SVG files contain elements that the built-in SVG parser does not support.

After installing Inkscape, restart MATLAB so the executable can be found on the system path.

## Optional: App Designer wrapper

This repository intentionally keeps the app as plain `.m` files. If you need a native `.mlapp` wrapper:

1. Open MATLAB App Designer.
2. Create a blank app.
3. In `StartupFcn`, call:

   ```matlab
   GroupFigureComposer_appdesigner_import
   ```

4. Save the wrapper as `GroupFigureComposer.mlapp`.

The wrapper is only a launcher; the implemented code remains in `GroupFigureComposerApp.m` and `+gfc/`.
