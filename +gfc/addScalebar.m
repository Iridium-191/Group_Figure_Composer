function h = addScalebar(ax, lengthValue, labelText, opts)
%ADDSCALEBAR Add a scale bar near the bottom-left of an axes.

arguments
    ax
    lengthValue (1,1) double {mustBePositive}
    labelText (1,:) char
    opts.Color (1,3) double = [0 0 0]
    opts.LineWidth (1,1) double {mustBePositive} = 2
end

xl = xlim(ax);
yl = ylim(ax);
x0 = xl(1) + 0.08 * diff(xl);
y0 = yl(1) + 0.12 * diff(yl);
if strcmp(ax.YDir, 'reverse')
    y0 = yl(2) - 0.12 * diff(yl);
end
hold(ax, 'on');
h.line = line(ax, [x0 x0 + lengthValue], [y0 y0], ...
    'Color', opts.Color, 'LineWidth', opts.LineWidth, 'DisplayName', 'scale_bar');
h.line.Tag = 'gfc_draggable';
h.text = text(ax, x0 + lengthValue / 2, y0, labelText, ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
    'Color', opts.Color, 'Interpreter', 'none', 'FontWeight', 'bold');
h.text.Tag = 'gfc_draggable';
hold(ax, 'off');
end
