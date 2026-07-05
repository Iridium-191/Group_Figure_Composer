function h = addHighlight(ax, x, y, opts)
%ADDHIGHLIGHT Add a simple point highlight annotation.

arguments
    ax
    x (1,1) double
    y (1,1) double
    opts.Color (1,3) double = [1 0 0]
    opts.Size (1,1) double = 70
end

hold(ax, 'on');
h = scatter(ax, x, y, opts.Size, 'o', 'MarkerEdgeColor', opts.Color, ...
    'MarkerFaceColor', 'none', 'LineWidth', 1.5, 'DisplayName', 'highlight');
hold(ax, 'off');
end
