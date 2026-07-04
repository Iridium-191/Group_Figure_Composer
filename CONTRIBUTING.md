# Contributing

Contributions are welcome if they keep the tool focused on reliable publication-figure assembly in MATLAB.

## Before opening a pull request

1. Start from a fresh branch.
2. Keep changes focused. Avoid mixing UI redesign, bug fixes, and unrelated refactors in one pull request.
3. Run the test suite from the repository root:

   ```matlab
   addpath(genpath(pwd))
   results = runtests("tests");
   assertSuccess(results)
   ```

4. Manually test the affected workflow in `GroupFigureComposer` if your change touches the GUI.
5. Update documentation when behavior, options, file formats, or requirements change.

## Coding style

- Keep reusable logic in the `+gfc/` package when possible.
- Keep GUI-only logic in `GroupFigureComposerApp.m`.
- Prefer name-value arguments for new user-facing functions.
- Use clear error identifiers such as `gfc:Module:Reason`.
- Avoid silent geometry changes in preview/export code; publication figures need predictable layout.
- Do not commit generated output files unless they are intentional documentation assets.

## Bug reports

A useful bug report should include:

- MATLAB version and operating system;
- whether Inkscape is installed, if the issue involves SVG import;
- a minimal input file or reproducible script when possible;
- expected behavior;
- actual behavior and the full MATLAB error message.

## Feature requests

Feature requests are easiest to evaluate when they include:

- the figure-composition problem being solved;
- a small example of the desired input and output;
- whether the feature should work in the GUI, `GroupFigureComposerLite`, or both.
