function lgd = copyLegendToAxes(srcAx, dstAx, srcChildren, dstChildren)
%COPYLEGENDTOAXES Copy a source legend while preserving selected objects.

lgd = gobjects(0);
sourceLegend = findSourceLegend(srcAx);
if isempty(sourceLegend) || ~strcmp(sourceLegend.Visible, 'on')
    return
end

[objects, names] = mappedLegendEntries(sourceLegend, srcChildren, dstChildren);
if isempty(objects)
    return
end
if numel(names) ~= numel(objects)
    names = names(1:min(numel(names), numel(objects)));
    objects = objects(1:numel(names));
end

try
    lgd = legend(dstAx, objects, cellstr(names), 'Interpreter', 'none');
catch
    return
end
copyLegendStyle(sourceLegend, lgd);
applyLegendPosition(sourceLegend, srcAx, lgd, dstAx);
end

function sourceLegend = findSourceLegend(srcAx)
sourceLegend = gobjects(0);
try
    sourceFig = ancestor(srcAx, 'figure');
    legends = findobj(sourceFig, 'Type', 'legend');
    legends = legends(arrayfun(@(h) isOwnedByAxes(h, srcAx), legends));
    if ~isempty(legends)
        sourceLegend = legends(1);
    end
catch
end
end

function [objects, names] = mappedLegendEntries(sourceLegend, srcChildren, dstChildren)
objects = gobjects(0);
names = string(sourceLegend.String);
try
    plotChildren = sourceLegend.PlotChildren;
catch
    plotChildren = gobjects(0);
end
if isempty(plotChildren)
    plotChildren = gfc.legendObjects(sourceLegend.Axes);
end

for k = 1:numel(plotChildren)
    idx = find(arrayfun(@(h) isequal(h, plotChildren(k)), srcChildren), 1);
    if isempty(idx) || idx > numel(dstChildren)
        continue
    end
    dst = dstChildren(idx);
    if isgraphics(dst)
        objects(end + 1, 1) = dst; %#ok<AGROW>
    end
end

if isempty(names)
    names = strings(1, numel(objects));
    for k = 1:numel(objects)
        try
            names(k) = string(objects(k).DisplayName);
        catch
            names(k) = "data" + k;
        end
    end
end
names = names(:).';
end

function copyLegendStyle(src, dst)
props = {'Location','Box','FontSize','FontName','FontWeight','FontAngle', ...
    'TextColor','Color','EdgeColor','Orientation','NumColumns','Interpreter','Visible'};
for i = 1:numel(props)
    try
        dst.(props{i}) = src.(props{i});
    catch
    end
end
end

function applyLegendPosition(srcLegend, srcAx, dstLegend, dstAx)
try
    if ~strcmpi(srcLegend.Location, 'none')
        return
    end
    [srcPos, srcFrame] = normalizedLegendAndAxes(srcLegend, srcAx);
    [~, dstFrame] = normalizedLegendAndAxes(dstLegend, dstAx);
    rel = [(srcPos(1) - srcFrame(1)) / max(srcFrame(3), eps), ...
        (srcPos(2) - srcFrame(2)) / max(srcFrame(4), eps), ...
        srcPos(3) / max(srcFrame(3), eps), srcPos(4) / max(srcFrame(4), eps)];
    dstLegend.Units = 'normalized';
    dstLegend.Location = 'none';
    dstLegend.Position = [dstFrame(1) + rel(1) * dstFrame(3), ...
        dstFrame(2) + rel(2) * dstFrame(4), ...
        rel(3) * dstFrame(3), rel(4) * dstFrame(4)];
catch
end
end

function [legendPos, axesPos] = normalizedLegendAndAxes(lgd, ax)
oldLegendUnits = lgd.Units;
oldAxesUnits = ax.Units;
cleanup = onCleanup(@() restoreUnits(lgd, oldLegendUnits, ax, oldAxesUnits));
lgd.Units = 'normalized';
ax.Units = 'normalized';
legendPos = lgd.Position;
try
    axesPos = ax.OuterPosition;
catch
    axesPos = ax.Position;
end
clear cleanup
end

function restoreUnits(lgd, legendUnits, ax, axesUnits)
try
    lgd.Units = legendUnits;
catch
end
try
    ax.Units = axesUnits;
catch
end
end

function tf = isOwnedByAxes(obj, ax)
tf = false;
try
    tf = isequal(obj.Axes, ax);
catch
end
end
