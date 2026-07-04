%DEMO_LITE Minimal example for the English GroupFigureComposerLite utility.
%
% Run this file from the repository root:
%   run("examples/demo_lite.m")

addpath(fileparts(fileparts(mfilename("fullpath"))));

outDir = tempdir;
figFile1 = fullfile(outDir, "gfc_lite_curve.fig");
figFile2 = fullfile(outDir, "gfc_lite_map.fig");
outputFile = fullfile(outDir, "gfc_lite_composite.png");

f1 = figure("Visible", "off", "Color", "w");
ax1 = axes(f1);
plot(ax1, linspace(0, 2*pi, 80), sin(linspace(0, 2*pi, 80)), ...
    "LineWidth", 1.5, "DisplayName", "signal");
xlabel(ax1, "x");
ylabel(ax1, "sin(x)");
title(ax1, "Line plot");
legend(ax1, "show");
savefig(f1, figFile1);
close(f1);

f2 = figure("Visible", "off", "Color", "w");
ax2 = axes(f2);
imagesc(ax2, peaks(80));
axis(ax2, "image");
title(ax2, "Map");
colorbar(ax2);
savefig(f2, figFile2);
close(f2);

GroupFigureComposerLite([figFile1 figFile2], char(outputFile), ...
    Rows=1, Cols=2, WidthPx=1200, HeightPx=520, DPI=150, ...
    FontName='Arial', FontSize=10);

fprintf("Composite saved to: %s\n", outputFile);
