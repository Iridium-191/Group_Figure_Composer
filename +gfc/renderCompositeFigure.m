function fig = renderCompositeFigure(panels, axesList, opts)
%RENDERCOMPOSITEFIGURE Build an export-ready standard MATLAB figure.

arguments
    panels (1,:) struct
    axesList
    opts.Rows (1,1) double {mustBeInteger,mustBePositive}
    opts.Cols (1,1) double {mustBeInteger,mustBePositive}
    opts.WidthPx (1,1) double {mustBePositive} = 900
    opts.HeightPx (1,1) double {mustBePositive} = 675
    opts.Gap (1,1) double {mustBeNonnegative} = 0.025
    opts.Margin (1,1) double {mustBeNonnegative} = 0.045
    opts.Visible (1,:) char = 'off'
    opts.Positions double = []
    opts.AxesPositions double = []
    opts.AxesPositionsAreAbsolute (1,1) logical = false
    opts.AxesPositionsAreFrame (1,1) logical = false
    opts.LabelPositions double = []
    opts.LabelPositionsAreAbsolute (1,1) logical = false
    opts.LabelFontName (1,:) char = 'Arial'
    opts.LabelFontSize (1,1) double {mustBePositive} = 11
end

fig = figure('Visible', opts.Visible, 'Color', 'w', 'Units', 'pixels', ...
    'Position', [80 80 opts.WidthPx opts.HeightPx], 'PaperPositionMode', 'auto', ...
    'Resize', 'off');
if isempty(opts.Positions)
    positions = gfc.panelPositions(panels, opts.Rows, opts.Cols, opts.Gap, opts.Margin);
else
    positions = opts.Positions;
end
if isempty(opts.LabelPositions)
    labelPositions = repmat([0.015 0.915 0.18 0.065], numel(panels), 1);
else
    labelPositions = opts.LabelPositions;
end
if isempty(opts.AxesPositions)
    axesPositions = zeros(numel(panels), 4);
    for k = 1:numel(panels)
        padding = min(max(panels(k).innerPadding, 0), 0.4);
        axesPositions(k, :) = [padding, padding, 1 - 2*padding, 1 - 2*padding];
    end
else
    axesPositions = opts.AxesPositions;
end

for k = 1:numel(panels)
    pos = positions(k, :);
    useOuterPosition = opts.AxesPositionsAreAbsolute && ~opts.AxesPositionsAreFrame;
    if opts.AxesPositionsAreAbsolute
        axesPos = axesPositions(k, :);
        ax = axes(fig, 'Units', 'normalized');
        placeAxes(ax, axesPos, useOuterPosition);
    else
        axesPos = relativeToFigure(pos, axesPositions(k, :));
        ax = axes(fig, 'Units', 'normalized', 'Position', axesPos, ...
            'ActivePositionProperty', 'position');
    end
    box(ax, 'on');
    if k <= numel(axesList) && isgraphics(axesList(k))
        src = axesList(k);
        copyAxesProps(src, ax);
        children = flipud(allchild(src));
        copiedChildren = gobjects(numel(children), 1);
        for j = 1:numel(children)
            try
                copied = copyobj(children(j), ax);
                if isgraphics(copied)
                    copiedChildren(j) = copied(1);
                end
            catch
            end
        end
        gfc.copyLegendToAxes(src, ax, children, copiedChildren);
        copyColorbar(src, ax);
    end
    placeAxes(ax, axesPos, useOuterPosition);
    labelPos = labelPositions(k, :);
    if opts.LabelPositionsAreAbsolute
        labelBox = labelPos;
    else
        labelBox = [pos(1) + labelPos(1) * pos(3), ...
            pos(2) + labelPos(2) * pos(4), labelPos(3) * pos(3), labelPos(4) * pos(4)];
    end
    labelBoxHandle = annotation(fig, 'textbox', labelBox, ...
        'String', sprintf(panels(k).labelFormat, panels(k).label), ...
        'EdgeColor', 'none', 'FontName', opts.LabelFontName, ...
        'FontWeight', 'bold', 'FontSize', opts.LabelFontSize, ...
        'VerticalAlignment', 'middle', 'FitBoxToText', 'off');
    try
        labelBoxHandle.Units = 'normalized';
        labelBoxHandle.Position = labelBox;
    catch
    end
end
end

function copyColorbar(src, dst)
try
    sourceFig = ancestor(src, 'figure');
    colorbars = findobj(sourceFig, 'Type', 'ColorBar');
    colorbars = colorbars(arrayfun(@(cb) isOwnedByAxes(cb, src), colorbars));
    if isempty(colorbars)
        return
    end
    cb = colorbar(dst);
    cb.Location = colorbars(1).Location;
    cb.FontSize = colorbars(1).FontSize;
    cb.FontName = colorbars(1).FontName;
    copyTextProps(colorbars(1).Label, cb.Label);
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

function out = relativeToFigure(panelPos, relPos)
out = [panelPos(1) + relPos(1)*panelPos(3), ...
       panelPos(2) + relPos(2)*panelPos(4), ...
       relPos(3)*panelPos(3), relPos(4)*panelPos(4)];
end

function placeAxes(ax, pos, useOuterPosition)
try
    ax.Units = 'normalized';
    if useOuterPosition
        try
            ax.ActivePositionProperty = 'outerposition';
        catch
        end
        try
            ax.PositionConstraint = 'outerposition';
        catch
        end
        ax.OuterPosition = pos;
    else
        try
            ax.ActivePositionProperty = 'position';
        catch
        end
        try
            ax.PositionConstraint = 'innerposition';
        catch
        end
        ax.Position = pos;
    end
catch
end
end

function copyAxesProps(src, dst)
props = {'XLim','YLim','ZLim','CLim','XScale','YScale','ZScale','XDir','YDir','ZDir', ...
    'FontName','FontSize','FontWeight','LineWidth','Box','TickDir','XGrid','YGrid','ZGrid', ...
    'Color','XColor','YColor','ZColor','Visible','DataAspectRatio','DataAspectRatioMode', ...
    'PlotBoxAspectRatio','PlotBoxAspectRatioMode'};
for i = 1:numel(props)
    try
        dst.(props{i}) = src.(props{i});
    catch
    end
end
copyRulerProps(src.XAxis, dst.XAxis);
copyRulerProps(src.YAxis, dst.YAxis);
copyRulerProps(src.ZAxis, dst.ZAxis);
try
    xlabel(dst, src.XLabel.String);
    copyAxisLabelProps(src.XLabel, dst.XLabel);
catch
end
try
    ylabel(dst, src.YLabel.String);
    copyAxisLabelProps(src.YLabel, dst.YLabel);
catch
end
try
    zlabel(dst, src.ZLabel.String);
    copyAxisLabelProps(src.ZLabel, dst.ZLabel);
catch
end
try
    title(dst, src.Title.String);
    copyAxisLabelProps(src.Title, dst.Title);
catch
end
try
    colormap(dst, colormap(src));
catch
end
end

function copyTextProps(src, dst)
props = {'FontName','FontSize','FontWeight','FontAngle','Color','Interpreter', ...
    'Units','Position','Rotation','HorizontalAlignment','VerticalAlignment'};
copyObjectProps(src, dst, props);
end

function copyAxisLabelProps(src, dst)
props = {'FontName','FontSize','FontWeight','FontAngle','Color','Interpreter', ...
    'Rotation','HorizontalAlignment','VerticalAlignment','Visible'};
copyObjectProps(src, dst, props);
end

function copyRulerProps(src, dst)
props = {'FontName','FontSize','FontWeight','Color','TickLabelInterpreter'};
copyObjectProps(src, dst, props);
end

function copyObjectProps(src, dst, props)
for i = 1:numel(props)
    try
        dst.(props{i}) = src.(props{i});
    catch
    end
end
end
