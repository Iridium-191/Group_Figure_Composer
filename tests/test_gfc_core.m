function tests = test_gfc_core
tests = functiontests(localfunctions);
end

function testDefaultLabels(testCase)
verifyEqual(testCase, gfc.defaultLabel(1), 'a');
verifyEqual(testCase, gfc.defaultLabel(26), 'z');
verifyEqual(testCase, gfc.defaultLabel(27), 'aa');
verifyEqual(testCase, gfc.defaultLabel(28), 'ab');
end

function testMergeAndUnmerge(testCase)
panels = gfc.createPanels(3, 3);
[panels, merged] = gfc.mergePanels(panels, 1, 1, 2, 2);
verifyEqual(testCase, merged.rowSpan, 2);
verifyEqual(testCase, merged.colSpan, 2);
verifyNumElements(testCase, panels, 6);
panels = gfc.unmergePanel(panels, merged.id);
cellList = arrayfun(@gfc.panelCells, panels, 'UniformOutput', false);
covered = vertcat(cellList{:});
verifyEqual(testCase, size(unique(covered, 'rows'), 1), 9);
end

function testCropRaster(testCase)
img = uint8(255 * ones(40, 50, 3));
img(12:28, 15:35, 1) = 0;
img(12:28, 15:35, 2) = 20;
img(12:28, 15:35, 3) = 200;
[cropped, rect] = gfc.cropRaster(img, 'Padding', 0);
verifyEqual(testCase, rect, [15 12 21 17]);
verifySize(testCase, cropped, [17 21 3]);
end

function testExtractGroupData(testCase)
fig = figure('Visible', 'off');
cleanup = onCleanup(@() close(fig));
ax = axes(fig);
plot(ax, 1:3, [2 4 6], 'DisplayName', 'curveA');
hold(ax, 'on');
plot(ax, 1:3, [3 6 9], 'DisplayName', '图例1');
panels = gfc.createPanels(1, 1);
infos = struct('sourcePath', 'synthetic.fig', 'assetType', 'fig', 'importReport', 'ok');
groupData = gfc.extractGroupData(ax, panels, infos, 'ProjectName', 'unit');
verifyTrue(testCase, isfield(groupData.fig1, 'curveA'));
verifyTrue(testCase, isfield(groupData.fig1, 'legend_002'));
verifyEqual(testCase, groupData.fig1.curveA.x, 1:3);
verifyEqual(testCase, groupData.fig1.legend_002.name, "图例1");
verifyEqual(testCase, groupData.fig1.legend_002.panelLabel, "a");
end

function testRenderAndExport(testCase)
figSrc = figure('Visible', 'off');
cleanupSrc = onCleanup(@() close(figSrc));
ax = axes(figSrc);
plot(ax, 1:5, (1:5).^2, 'DisplayName', 'quad');
panels = gfc.createPanels(1, 1);
fig = gfc.renderCompositeFigure(panels, ax, 'Rows', 1, 'Cols', 1, 'Visible', 'off');
cleanup = onCleanup(@() close(fig));
pngFile = fullfile(tempdir, 'gfc_test_export.png');
figFile = fullfile(tempdir, 'gfc_test_export.fig');
gfc.exportComposite(fig, pngFile, 'DPI', 100);
gfc.exportComposite(fig, figFile, 'DPI', 100);
verifyTrue(testCase, isfile(pngFile));
verifyTrue(testCase, isfile(figFile));
delete(pngFile);
delete(figFile);
end

function testRenderDoesNotForceImageAspectOrLegend(testCase)
figSrc = figure('Visible', 'off');
cleanupSrc = onCleanup(@() close(figSrc));
ax = axes(figSrc);
plot(ax, 1:5, (1:5).^2, 'DisplayName', 'hasName');
verifyEqual(testCase, ax.DataAspectRatioMode, 'auto');
panels = gfc.createPanels(1, 1);
fig = gfc.renderCompositeFigure(panels, ax, 'Rows', 1, 'Cols', 1, 'Visible', 'off');
cleanup = onCleanup(@() close(fig));
renderedAx = findobj(fig, 'Type', 'axes');
verifyEqual(testCase, renderedAx.DataAspectRatioMode, 'auto');
verifyEmpty(testCase, findobj(fig, 'Type', 'legend'));
end

function testRenderUsesExplicitAxesPositions(testCase)
figSrc = figure('Visible', 'off');
cleanupSrc = onCleanup(@() close(figSrc));
ax = axes(figSrc);
plot(ax, 1:3, 2:4);
panels = gfc.createPanels(1, 1);
panelPos = [0.10 0.20 0.70 0.60];
axesPos = [0.20 0.25 0.50 0.40];
fig = gfc.renderCompositeFigure(panels, ax, 'Rows', 1, 'Cols', 1, ...
    'Visible', 'off', 'Positions', panelPos, 'AxesPositions', axesPos);
cleanup = onCleanup(@() close(fig));
renderedAx = findobj(fig, 'Type', 'axes');
expected = [panelPos(1) + axesPos(1)*panelPos(3), ...
    panelPos(2) + axesPos(2)*panelPos(4), ...
    axesPos(3)*panelPos(3), axesPos(4)*panelPos(4)];
verifyEqual(testCase, renderedAx.Position, expected, 'AbsTol', 1e-12);
end

function testRenderUsesAbsoluteCanvasGeometry(testCase)
figSrc = figure('Visible', 'off');
cleanupSrc = onCleanup(@() close(figSrc));
ax = axes(figSrc);
plot(ax, 1:3, 2:4);
panels = gfc.createPanels(1, 1);
panelPos = [0.11 0.22 0.33 0.44];
axesPos = [0.18 0.27 0.39 0.41];
labelPos = [0.07 0.81 0.12 0.06];
fig = gfc.renderCompositeFigure(panels, ax, 'Rows', 1, 'Cols', 1, ...
    'Visible', 'off', 'Positions', panelPos, ...
    'AxesPositions', axesPos, 'AxesPositionsAreAbsolute', true, ...
    'LabelPositions', labelPos, 'LabelPositionsAreAbsolute', true);
cleanup = onCleanup(@() close(fig));
renderedAx = findobj(fig, 'Type', 'axes');
verifyEqual(testCase, renderedAx.OuterPosition, axesPos, 'AbsTol', 1e-12);
labels = findall(fig, 'Type', 'textboxshape');
verifyEqual(testCase, labels.Position, labelPos, 'AbsTol', 1e-12);
end

function testRenderUsesAbsoluteFrameGeometry(testCase)
figSrc = figure('Visible', 'off');
cleanupSrc = onCleanup(@() close(figSrc));
ax = axes(figSrc);
plot(ax, 1:3, 2:4);
panels = gfc.createPanels(1, 1);
panelPos = [0.11 0.22 0.33 0.44];
framePos = [0.18 0.27 0.39 0.41];
fig = gfc.renderCompositeFigure(panels, ax, 'Rows', 1, 'Cols', 1, ...
    'Visible', 'off', 'Positions', panelPos, ...
    'AxesPositions', framePos, 'AxesPositionsAreAbsolute', true, ...
    'AxesPositionsAreFrame', true);
cleanup = onCleanup(@() close(fig));
renderedAx = findobj(fig, 'Type', 'axes');
verifyEqual(testCase, renderedAx.Position, framePos, 'AbsTol', 1e-12);
end

function testRenderDoesNotDrawPanelFrames(testCase)
figSrc = figure('Visible', 'off');
cleanupSrc = onCleanup(@() close(figSrc));
ax = axes(figSrc);
plot(ax, 1:3, 2:4);
panels = gfc.createPanels(1, 2);
fig = gfc.renderCompositeFigure(panels, [ax ax], 'Rows', 1, 'Cols', 2, ...
    'Visible', 'off');
cleanup = onCleanup(@() close(fig));
verifyEmpty(testCase, findall(fig, 'Type', 'rectangle'));
end

function testRenderCopiesUnifiedFontLayers(testCase)
figSrc = figure('Visible', 'off');
cleanupSrc = onCleanup(@() close(figSrc));
ax = axes(figSrc);
plot(ax, 1:5, (1:5).^2, 'DisplayName', 'quad');
title(ax, 'Title Text');
xlabel(ax, 'X Text');
ylabel(ax, 'Y Text');
legend(ax, 'show');
cb = colorbar(ax);
cb.Label.String = 'Intensity';
gfc.styleAxes(ax, 'FontName', 'Arial', 'FontSize', 13, 'TickDir', 'in');
panels = gfc.createPanels(1, 1);

fig = gfc.renderCompositeFigure(panels, ax, 'Rows', 1, 'Cols', 1, 'Visible', 'off');
cleanup = onCleanup(@() close(fig));
renderedAx = findobj(fig, 'Type', 'axes');
verifyEqual(testCase, renderedAx.FontName, 'Arial');
verifyEqual(testCase, renderedAx.FontSize, 13);
verifyEqual(testCase, renderedAx.TickDir, 'in');
verifyEqual(testCase, renderedAx.XAxis.FontName, 'Arial');
verifyEqual(testCase, renderedAx.XAxis.FontSize, 13);
verifyEqual(testCase, renderedAx.YAxis.FontName, 'Arial');
verifyEqual(testCase, renderedAx.YAxis.FontSize, 13);
verifyEqual(testCase, renderedAx.Title.FontSize, 13);
verifyEqual(testCase, renderedAx.XLabel.FontSize, 13);
verifyEqual(testCase, renderedAx.YLabel.FontSize, 13);
renderedLegend = findobj(fig, 'Type', 'legend');
verifyEqual(testCase, renderedLegend.FontSize, 13);
renderedColorbar = findobj(fig, 'Type', 'ColorBar');
verifyEqual(testCase, renderedColorbar.FontSize, 13);
verifyEqual(testCase, renderedColorbar.Label.FontSize, 13);
end

function testRenderPreservesExplicitLegendEntries(testCase)
figSrc = figure('Visible', 'off');
cleanupSrc = onCleanup(@() close(figSrc));
ax = axes(figSrc);
l1 = plot(ax, 1:3, 1:3, 'DisplayName', 'curveA');
hold(ax, 'on');
l2 = plot(ax, 1:3, 2:4, 'DisplayName', 'curveB');
plot(ax, 1:3, 3:5, 'DisplayName', 'curveC');
legend(ax, [l2 l1], {'curveB','curveA'}, 'Interpreter', 'none');

panels = gfc.createPanels(1, 1);
fig = gfc.renderCompositeFigure(panels, ax, 'Rows', 1, 'Cols', 1, 'Visible', 'off');
cleanup = onCleanup(@() close(fig));
renderedLegend = findobj(fig, 'Type', 'legend');
verifyNumElements(testCase, renderedLegend.String, 2);
verifyEqual(testCase, string(renderedLegend.String{1}), "curveB");
verifyEqual(testCase, string(renderedLegend.String{2}), "curveA");
end

function testBuiltinPalettesAreValid(testCase)
names = {'Okabe-Ito','Nature Muted','Science Bright','Tableau 10', ...
    'ColorBrewer Set2','ColorBrewer Dark2','Gray','Viridis','Cividis', ...
    'Magma','Inferno','Plasma','Turbo','Parula','Jet','CoolWarm'};
for k = 1:numel(names)
    palette = gfc.builtinPalettes(names{k}, 7);
    verifySize(testCase, palette, [7 3], names{k});
    verifyGreaterThanOrEqual(testCase, palette, 0, names{k});
    verifyLessThanOrEqual(testCase, palette, 1, names{k});
end
end

function testApplyObjectColorAndPaletteTargets(testCase)
fig = figure('Visible', 'off');
cleanup = onCleanup(@() close(fig));
ax = axes(fig);
l1 = plot(ax, 1:3, 1:3);
hold(ax, 'on');
l2 = plot(ax, 1:3, 3:-1:1);
sc = scatter(ax, 1:3, [2 2 2]);
rgb = [0.2 0.4 0.8];
verifyTrue(testCase, gfc.applyObjectColor(sc, rgb));
verifyEqual(testCase, sc.MarkerFaceColor, rgb);
verifyEqual(testCase, sc.MarkerEdgeColor, rgb);

palette = [1 0 0; 0 1 0];
changed = gfc.applyPalette(ax, palette, 'order', 'Target', 'allLines');
verifyEqual(testCase, changed, 2);
lineColors = [l1.Color; l2.Color];
verifyTrue(testCase, all(ismember(lineColors, palette, 'rows')));
end

function testApplyLineStyle(testCase)
fig = figure('Visible', 'off');
cleanup = onCleanup(@() close(fig));
ax = axes(fig);
ln = plot(ax, 1:3, 1:3);
changed = gfc.applyLineStyle(ln, 'LineStyle', '--', 'LineWidth', 2.5);
verifyEqual(testCase, changed, 1);
verifyEqual(testCase, ln.LineStyle, '--');
verifyEqual(testCase, ln.LineWidth, 2.5);
end

function testStyleAxesCanPreserveChildLineWidth(testCase)
fig = figure('Visible', 'off');
cleanup = onCleanup(@() close(fig));
ax = axes(fig);
ln = plot(ax, 1:3, 1:3);
ln.LineWidth = 3.5;
gfc.styleAxes(ax, 'FontName', 'Arial', 'FontSize', 12, ...
    'LineWidth', 1, 'ApplyChildLineWidth', false);
verifyEqual(testCase, ax.LineWidth, 1);
verifyEqual(testCase, ln.LineWidth, 3.5);
end

function testRenderCopiesMapColormapAndCLim(testCase)
figSrc = figure('Visible', 'off');
cleanupSrc = onCleanup(@() close(figSrc));
ax = axes(figSrc);
imagesc(ax, magic(5));
cmap = gfc.builtinPalettes('Viridis', 16);
colormap(ax, cmap);
ax.CLim = [5 20];
panels = gfc.createPanels(1, 1);

fig = gfc.renderCompositeFigure(panels, ax, 'Rows', 1, 'Cols', 1, 'Visible', 'off');
cleanup = onCleanup(@() close(fig));
renderedAx = findobj(fig, 'Type', 'axes');
verifyEqual(testCase, renderedAx.CLim, [5 20]);
verifyEqual(testCase, colormap(renderedAx), cmap, 'AbsTol', 1e-12);
end

function testThreeColorColormap(testCase)
colors = [0 0 1; 1 1 1; 1 0 0];
cmap = gfc.threeColorColormap(colors, 5);
verifySize(testCase, cmap, [5 3]);
verifyEqual(testCase, cmap(1, :), colors(1, :), 'AbsTol', 1e-12);
verifyEqual(testCase, cmap(3, :), colors(2, :), 'AbsTol', 1e-12);
verifyEqual(testCase, cmap(end, :), colors(3, :), 'AbsTol', 1e-12);
end

function testControlPointColormap(testCase)
colors = [0 0 0; 1 0 0; 1 1 0; 1 1 1];
positions = [10; 20; 40; 70];
cmap = gfc.controlPointColormap(colors, positions, 7);
verifySize(testCase, cmap, [7 3]);
verifyEqual(testCase, cmap(1, :), colors(1, :), 'AbsTol', 1e-12);
verifyEqual(testCase, cmap(end, :), colors(end, :), 'AbsTol', 1e-12);
verifyGreaterThanOrEqual(testCase, cmap, 0);
verifyLessThanOrEqual(testCase, cmap, 1);

exact = gfc.controlPointColormap(colors, [0; 1; 2; 3], 4);
verifyEqual(testCase, exact, colors, 'AbsTol', 1e-12);
verifyError(testCase, @() gfc.controlPointColormap(colors, [0; 1; 1; 3], 16), ...
    'gfc:controlPointColormap:DuplicatePositions');
end

function testAlignFrameGridAlignsRowsAndColumns(testCase)
panels = gfc.createPanels(2, 2);
panelPositions = gfc.panelPositions(panels, 2, 2, 0.04, 0.05);
axesPositions = [0.12 0.13 0.75 0.70; ...
    0.08 0.18 0.78 0.62; ...
    0.16 0.10 0.70 0.76; ...
    0.10 0.12 0.82 0.72];
inset = repmat([0.02 0.03 0.01 0.02], 4, 1);
frameRects = zeros(4, 4);
for k = 1:4
    outer = [panelPositions(k, 1) + axesPositions(k, 1) * panelPositions(k, 3), ...
        panelPositions(k, 2) + axesPositions(k, 2) * panelPositions(k, 4), ...
        axesPositions(k, 3) * panelPositions(k, 3), ...
        axesPositions(k, 4) * panelPositions(k, 4)];
    frameRects(k, :) = [outer(1) + inset(k, 1), outer(2) + inset(k, 2), ...
        outer(3) - inset(k, 1) - inset(k, 3), ...
        outer(4) - inset(k, 2) - inset(k, 4)];
end
newAxesPositions = gfc.alignFrameGrid(panels, panelPositions, axesPositions, frameRects);
newFrameRects = zeros(4, 4);
for k = 1:4
    outer = [panelPositions(k, 1) + newAxesPositions(k, 1) * panelPositions(k, 3), ...
        panelPositions(k, 2) + newAxesPositions(k, 2) * panelPositions(k, 4), ...
        newAxesPositions(k, 3) * panelPositions(k, 3), ...
        newAxesPositions(k, 4) * panelPositions(k, 4)];
    newFrameRects(k, :) = [outer(1) + inset(k, 1), outer(2) + inset(k, 2), ...
        outer(3) - inset(k, 1) - inset(k, 3), ...
        outer(4) - inset(k, 2) - inset(k, 4)];
end
verifyEqual(testCase, newFrameRects(1, [2 4]), newFrameRects(2, [2 4]), 'AbsTol', 1e-12);
verifyEqual(testCase, newFrameRects(3, [2 4]), newFrameRects(4, [2 4]), 'AbsTol', 1e-12);
verifyEqual(testCase, newFrameRects(1, [1 3]), newFrameRects(3, [1 3]), 'AbsTol', 1e-12);
verifyEqual(testCase, newFrameRects(2, [1 3]), newFrameRects(4, [1 3]), 'AbsTol', 1e-12);
end

function testAlignFrameGridSupportsMergedOuterPerimeter(testCase)
[panels, ~] = gfc.mergePanels(gfc.createPanels(2, 2), 1, 1, 2, 1);
panelPositions = gfc.panelPositions(panels, 2, 2, 0.04, 0.05);
axesPositions = [0.12 0.12 0.76 0.78; ...
    0.18 0.22 0.66 0.58; ...
    0.10 0.16 0.78 0.62];
inset = [0.018 0.030 0.012 0.020; ...
    0.026 0.035 0.014 0.025; ...
    0.020 0.028 0.018 0.022];
frameRects = frameRectsFromAxes(panelPositions, axesPositions, inset);

newAxesPositions = gfc.alignFrameGrid(panels, panelPositions, axesPositions, frameRects);
newFrameRects = frameRectsFromAxes(panelPositions, newAxesPositions, inset);
topEdge = @(r) newFrameRects(r, 2) + newFrameRects(r, 4);
rightEdge = @(r) newFrameRects(r, 1) + newFrameRects(r, 3);

verifyEqual(testCase, topEdge(1), topEdge(2), 'AbsTol', 1e-12);
verifyEqual(testCase, newFrameRects(1, 2), newFrameRects(3, 2), 'AbsTol', 1e-12);
verifyEqual(testCase, newFrameRects(2, 1), newFrameRects(3, 1), 'AbsTol', 1e-12);
verifyEqual(testCase, rightEdge(2), rightEdge(3), 'AbsTol', 1e-12);
end

function testAddStyledLegend(testCase)
fig = figure('Visible', 'off');
cleanup = onCleanup(@() close(fig));
ax = axes(fig);
plot(ax, 1:3, 1:3, 'DisplayName', 'curveA');
hold(ax, 'on');
plot(ax, 1:3, 3:-1:1);
lgd = gfc.addStyledLegend(ax, 'FontName', 'Arial', 'FontSize', 13);
verifyEqual(testCase, lgd.FontName, 'Arial');
verifyEqual(testCase, lgd.FontSize, 13);
verifyEqual(testCase, string(lgd.String{1}), "curveA");
verifyEqual(testCase, string(lgd.String{2}), "data2");
end

function testAddStyledLegendCanFilterObjects(testCase)
fig = figure('Visible', 'off');
cleanup = onCleanup(@() close(fig));
ax = axes(fig);
l1 = plot(ax, 1:3, 1:3, 'DisplayName', 'showA');
hold(ax, 'on');
l2 = plot(ax, 1:3, 3:-1:1, 'DisplayName', 'showB');
lgd = gfc.addStyledLegend(ax, 'FontName', 'Arial', 'FontSize', 12, ...
    'Objects', [l2 l1]);
verifyEqual(testCase, lgd.FontSize, 12);
verifyEqual(testCase, string(lgd.String{1}), "showB");
verifyEqual(testCase, string(lgd.String{2}), "showA");
end

function testStyleAxesAppliesAllTextLayers(testCase)
fig = figure('Visible', 'off');
cleanup = onCleanup(@() close(fig));
ax = axes(fig);
plot(ax, 1:3, 2:4, 'DisplayName', 'curve');
title(ax, 'Title Text');
xlabel(ax, 'X Text');
ylabel(ax, 'Y Text');
lgd = legend(ax, 'show');
cb = colorbar(ax);
cb.Label.String = 'Intensity';

gfc.styleAxes(ax, 'FontName', 'Arial', 'FontSize', 14, 'LineWidth', 1.5);

verifyEqual(testCase, ax.FontName, 'Arial');
verifyEqual(testCase, ax.FontSize, 14);
verifyEqual(testCase, ax.TickDir, 'in');
verifyEqual(testCase, ax.XAxis.FontName, 'Arial');
verifyEqual(testCase, ax.XAxis.FontSize, 14);
verifyEqual(testCase, ax.YAxis.FontName, 'Arial');
verifyEqual(testCase, ax.YAxis.FontSize, 14);
verifyEqual(testCase, ax.Title.FontName, 'Arial');
verifyEqual(testCase, ax.Title.FontSize, 14);
verifyEqual(testCase, ax.XLabel.FontName, 'Arial');
verifyEqual(testCase, ax.XLabel.FontSize, 14);
verifyEqual(testCase, ax.YLabel.FontName, 'Arial');
verifyEqual(testCase, ax.YLabel.FontSize, 14);
verifyEqual(testCase, lgd.FontName, 'Arial');
verifyEqual(testCase, lgd.FontSize, 14);
verifyEqual(testCase, cb.FontName, 'Arial');
verifyEqual(testCase, cb.FontSize, 14);
verifyEqual(testCase, cb.Label.FontName, 'Arial');
verifyEqual(testCase, cb.Label.FontSize, 14);
end

function testImportSimpleSvg(testCase)
svgFile = fullfile(tempdir, 'gfc_simple.svg');
fid = fopen(svgFile, 'w');
fprintf(fid, ['<svg viewBox="0 0 100 80" xmlns="http://www.w3.org/2000/svg">' ...
    '<rect x="10" y="10" width="30" height="20" stroke="#ff0000" fill="none"/>' ...
    '<line x1="0" y1="0" x2="80" y2="60" stroke="#0000ff" stroke-width="2"/>' ...
    '<text x="5" y="70">label</text></svg>']);
fclose(fid);
cleanupFile = onCleanup(@() delete(svgFile));
fig = figure('Visible', 'off');
cleanupFig = onCleanup(@() close(fig));
ax = axes(fig);
report = gfc.importSvgToAxes(ax, svgFile, 'AllowInkscapeFallback', false);
verifyTrue(testCase, contains(report, 'SVG parsed'));
verifyGreaterThanOrEqual(testCase, numel(allchild(ax)), 3);
end

function frameRects = frameRectsFromAxes(panelPositions, axesPositions, inset)
frameRects = zeros(size(axesPositions));
for k = 1:size(axesPositions, 1)
    outer = [panelPositions(k, 1) + axesPositions(k, 1) * panelPositions(k, 3), ...
        panelPositions(k, 2) + axesPositions(k, 2) * panelPositions(k, 4), ...
        axesPositions(k, 3) * panelPositions(k, 3), ...
        axesPositions(k, 4) * panelPositions(k, 4)];
    frameRects(k, :) = [outer(1) + inset(k, 1), outer(2) + inset(k, 2), ...
        outer(3) - inset(k, 1) - inset(k, 3), ...
        outer(4) - inset(k, 2) - inset(k, 4)];
end
end
