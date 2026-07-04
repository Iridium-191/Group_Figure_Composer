function panels = unmergePanel(panels, panelId)
%UNMERGEPANEL Split one merged panel back into 1x1 cells.

arguments
    panels (1,:) struct
    panelId (1,1) double {mustBeInteger,mustBePositive}
end

idx = find([panels.id] == panelId, 1);
if isempty(idx)
    error('gfc:unmergePanel:UnknownPanel', '找不到指定 panel。');
end

p = panels(idx);
panels(idx) = [];
nextId = max([0, panels.id]) + 1;
cells = gfc.panelCells(p);
for k = 1:size(cells, 1)
    q = p;
    q.id = nextId;
    q.row = cells(k, 1);
    q.col = cells(k, 2);
    q.rowSpan = 1;
    q.colSpan = 1;
    q.label = gfc.defaultLabel(numel(panels) + 1);
    q.sourcePath = '';
    q.assetType = '';
    q.importReport = 'Split from merged panel.';
    panels(end + 1) = q; %#ok<AGROW>
    nextId = nextId + 1;
end

[~, order] = sortrows([[panels.row].', [panels.col].', [panels.id].']);
panels = panels(order);
end
