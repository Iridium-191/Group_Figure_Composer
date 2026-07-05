function positions = panelPositions(panels, rows, cols, gap, margin)
%PANELPOSITIONS Convert panel grid specs to normalized figure positions.

arguments
    panels (1,:) struct
    rows (1,1) double {mustBeInteger,mustBePositive}
    cols (1,1) double {mustBeInteger,mustBePositive}
    gap (1,1) double {mustBeNonnegative} = 0.025
    margin (1,1) double {mustBeNonnegative} = 0.045
end

w = (1 - 2 * margin - (cols - 1) * gap) / cols;
h = (1 - 2 * margin - (rows - 1) * gap) / rows;
positions = zeros(numel(panels), 4);

for k = 1:numel(panels)
    x = margin + (panels(k).col - 1) * (w + gap);
    top = 1 - margin - (panels(k).row - 1) * (h + gap);
    height = panels(k).rowSpan * h + (panels(k).rowSpan - 1) * gap;
    width = panels(k).colSpan * w + (panels(k).colSpan - 1) * gap;
    y = top - height;
    positions(k, :) = [x, y, width, height];
end
end
