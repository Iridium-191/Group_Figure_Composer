function [panels, mergedPanel] = mergePanels(panels, row, col, rowSpan, colSpan)
%MERGEPANELS Merge a rectangular range if it does not partially cut panels.

arguments
    panels (1,:) struct
    row (1,1) double {mustBeInteger,mustBePositive}
    col (1,1) double {mustBeInteger,mustBePositive}
    rowSpan (1,1) double {mustBeInteger,mustBePositive}
    colSpan (1,1) double {mustBeInteger,mustBePositive}
end

targetRows = row:(row + rowSpan - 1);
targetCols = col:(col + colSpan - 1);
inside = false(1, numel(panels));
covered = [];

for k = 1:numel(panels)
    cells = gfc.panelCells(panels(k));
    in = ismember(cells(:,1), targetRows) & ismember(cells(:,2), targetCols);
    if any(in) && ~all(in)
        error('gfc:mergePanels:PartialOverlap', ...
            '合并区域不能切开已有 panel。请先取消相关合并。');
    end
    if all(in)
        inside(k) = true;
        covered = [covered; cells]; %#ok<AGROW>
    end
end

expected = numel(targetRows) * numel(targetCols);
if size(unique(covered, 'rows'), 1) ~= expected
    error('gfc:mergePanels:IncompleteRange', '合并区域不是完整矩形。');
end

base = panels(find(inside, 1, 'first'));
base.row = row;
base.col = col;
base.rowSpan = rowSpan;
base.colSpan = colSpan;
base.sourcePath = '';
base.assetType = '';
base.importReport = 'Merged panel; import a new asset.';

panels(inside) = [];
panels(end + 1) = base;
panels = sortPanels(panels);
mergedPanel = base;
end

function panels = sortPanels(panels)
[~, order] = sortrows([[panels.row].', [panels.col].', [panels.id].']);
panels = panels(order);
for k = 1:numel(panels)
    if strlength(string(panels(k).label)) == 0
        panels(k).label = gfc.defaultLabel(k);
    end
end
end
