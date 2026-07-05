function cmap = controlPointColormap(colors, positions, n)
%CONTROLPOINTCOLORMAP Interpolate RGB control points into a colormap.
%
% POSITIONS may be normalized [0,1] locations or arbitrary color-axis
% coordinates. They are normalized from the first to last control point.

arguments
    colors (:,3) double
    positions (:,1) double
    n (1,1) double {mustBeInteger,mustBePositive} = 256
end

if size(colors, 1) ~= numel(positions)
    error('gfc:controlPointColormap:SizeMismatch', ...
        'The number of colors must match the number of positions.');
end
if size(colors, 1) < 2
    error('gfc:controlPointColormap:TooFewStops', ...
        'At least two color stops are required.');
end
if any(~isfinite(colors), 'all') || any(~isfinite(positions))
    error('gfc:controlPointColormap:NonFinite', ...
        'Colors and positions must be finite numeric values.');
end

colors = min(max(colors, 0), 1);
[positions, order] = sort(positions(:));
colors = colors(order, :);
if any(diff(positions) <= 0)
    error('gfc:controlPointColormap:DuplicatePositions', ...
        'Color-axis positions must be unique.');
end

span = positions(end) - positions(1);
if span <= 0
    error('gfc:controlPointColormap:InvalidPositions', ...
        'The last color-axis position must be larger than the first.');
end
anchors = (positions - positions(1)) ./ span;

if n == 1
    cmap = interp1(anchors, colors, 0.5, 'linear');
else
    cmap = interp1(anchors, colors, linspace(0, 1, n).', 'linear');
end
cmap = min(max(cmap, 0), 1);
end
