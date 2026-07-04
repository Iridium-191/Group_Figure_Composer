function report = importFigToAxes(ax, filename)
%IMPORTFIGTOAXES Copy the first data axes from a .fig file into AX.

arguments
    ax
    filename (1,:) char
end

sourceFig = openfig(filename, 'invisible');
cleanup = onCleanup(@() close(sourceFig));
sourceAxes = findobj(sourceFig, 'Type', 'axes', '-not', 'Tag', 'legend', '-not', 'Tag', 'Colorbar');
if isempty(sourceAxes)
    error('gfc:importFigToAxes:NoAxes', 'FIG 文件中没有可导入的坐标轴。');
end
sourceAxes = flipud(sourceAxes(:));
src = sourceAxes(1);

cla(ax);
delete(allchild(ax));
copyAxesStyle(src, ax);
children = flipud(allchild(src));
for k = 1:numel(children)
    try
        copyobj(children(k), ax);
    catch
        % Some annotation-like children cannot be reparented into UIAxes.
    end
end
applyDisplayNames(src, ax);
report = sprintf('FIG imported from %s. %d axes found; first axes copied.', filename, numel(sourceAxes));
end

function copyAxesStyle(src, dst)
props = {'XLim','YLim','ZLim','CLim','XScale','YScale','ZScale','XDir','YDir','ZDir', ...
    'FontName','FontSize','FontWeight','LineWidth','Box','TickDir','XGrid','YGrid','ZGrid', ...
    'Color','XColor','YColor','ZColor','DataAspectRatio','DataAspectRatioMode', ...
    'PlotBoxAspectRatio','PlotBoxAspectRatioMode'};
for i = 1:numel(props)
    try
        dst.(props{i}) = src.(props{i});
    catch
    end
end
try
    xlabel(dst, src.XLabel.String);
catch
end
try
    ylabel(dst, src.YLabel.String);
catch
end
try
    zlabel(dst, src.ZLabel.String);
catch
end
try
    title(dst, src.Title.String);
catch
end
try
    colormap(dst, colormap(src));
catch
end
end

function applyDisplayNames(src, dst)
srcLegend = findobj(ancestor(src, 'figure'), 'Type', 'legend');
if isempty(srcLegend)
    return
end
try
    labels = string(srcLegend(1).String);
    plotted = findobj(dst, '-property', 'DisplayName');
    plotted = flipud(plotted(:));
    for k = 1:min(numel(labels), numel(plotted))
        plotted(k).DisplayName = labels(k);
    end
    legend(dst, 'show', 'Interpreter', 'none');
catch
end
end
