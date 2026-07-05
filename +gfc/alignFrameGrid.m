function axesPositions = alignFrameGrid(panels, panelPositions, axesPositions, frameRects)
%ALIGNFRAMEGRID Align plot-box frame edges by adjusting axes positions.
%
% FRAME_RECTS are measured in normalized canvas coordinates. AXES_POSITIONS
% are relative to each panel and describe the axes outer box.

arguments
    panels (1,:) struct
    panelPositions (:,4) double
    axesPositions (:,4) double
    frameRects (:,4) double
end

n = numel(panels);
if size(panelPositions, 1) ~= n || size(axesPositions, 1) ~= n || size(frameRects, 1) ~= n
    error('gfc:alignFrameGrid:SizeMismatch', ...
        'Panel, axes-position, and frame-rectangle counts must match.');
end

startRows = zeros(n, 1);
endRows = zeros(n, 1);
startCols = zeros(n, 1);
endCols = zeros(n, 1);
for k = 1:n
    startRows(k) = panels(k).row;
    endRows(k) = panels(k).row + panels(k).rowSpan - 1;
    startCols(k) = panels(k).col;
    endCols(k) = panels(k).col + panels(k).colSpan - 1;
end

maxRow = max(endRows);
maxCol = max(endCols);
rowBottom = nan(maxRow, 1);
rowTop = nan(maxRow, 1);
colLeft = nan(maxCol, 1);
colRight = nan(maxCol, 1);
frameTop = frameRects(:, 2) + frameRects(:, 4);
frameRight = frameRects(:, 1) + frameRects(:, 3);

for r = 1:maxRow
    rowTop(r) = finiteMedian(frameTop(startRows == r));
    rowBottom(r) = finiteMedian(frameRects(endRows == r, 2));
end
for c = 1:maxCol
    colLeft(c) = finiteMedian(frameRects(startCols == c, 1));
    colRight(c) = finiteMedian(frameRight(endCols == c));
end

for k = 1:n
    target = [colLeft(startCols(k)), rowBottom(endRows(k)), ...
        colRight(endCols(k)) - colLeft(startCols(k)), ...
        rowTop(startRows(k)) - rowBottom(endRows(k))];
    if any(~isfinite(target)) || any(target(3:4) <= 0)
        continue
    end
    outer = axesOuterRect(panelPositions(k, :), axesPositions(k, :));
    frame = frameRects(k, :);
    inset = [frame(1) - outer(1), frame(2) - outer(2), ...
        outer(1) + outer(3) - frame(1) - frame(3), ...
        outer(2) + outer(4) - frame(2) - frame(4)];
    if any(~isfinite(inset))
        continue
    end
    newOuter = [target(1) - inset(1), target(2) - inset(2), ...
        target(3) + inset(1) + inset(3), target(4) + inset(2) + inset(4)];
    axesPositions(k, :) = clampRelativeAxes(relativeToPanel(panelPositions(k, :), newOuter));
end
end

function rect = axesOuterRect(panelPos, axesPos)
rect = [panelPos(1) + axesPos(1) * panelPos(3), ...
    panelPos(2) + axesPos(2) * panelPos(4), ...
    axesPos(3) * panelPos(3), axesPos(4) * panelPos(4)];
end

function rel = relativeToPanel(panelPos, rect)
rel = [(rect(1) - panelPos(1)) / max(panelPos(3), eps), ...
    (rect(2) - panelPos(2)) / max(panelPos(4), eps), ...
    rect(3) / max(panelPos(3), eps), rect(4) / max(panelPos(4), eps)];
end

function pos = clampRelativeAxes(pos)
minSize = 0.04;
pos(~isfinite(pos)) = 0;
pos(3:4) = max(pos(3:4), minSize);
pos(1:2) = max(pos(1:2), 0);
if pos(1) + pos(3) > 1
    pos(3) = min(pos(3), 1);
    pos(1) = max(0, 1 - pos(3));
end
if pos(2) + pos(4) > 1
    pos(4) = min(pos(4), 1);
    pos(2) = max(0, 1 - pos(4));
end
end

function value = finiteMedian(values)
values = values(isfinite(values));
if isempty(values)
    value = NaN;
else
    value = median(values);
end
end
