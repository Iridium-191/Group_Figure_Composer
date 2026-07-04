function groupData = extractGroupData(axesList, panels, assetInfos, opts)
%EXTRACTGROUPDATA Collect plot data into a MAT-friendly structure.

arguments
    axesList
    panels (1,:) struct
    assetInfos = struct([])
    opts.ProjectName (1,:) char = 'GroupFigureComposer'
end

groupData = struct();
groupData.project.name = opts.ProjectName;
groupData.project.createdAt = string(datetime('now'));
groupData.project.matlabVersion = string(version);
groupData.panelMap = struct([]);

for k = 1:numel(panels)
    figField = sprintf('fig%d', k);
    groupData.(figField).panelLabel = string(panels(k).label);
    groupData.(figField).panelId = panels(k).id;
    groupData.(figField).grid = [panels(k).row panels(k).col panels(k).rowSpan panels(k).colSpan];
    if k <= numel(assetInfos)
        groupData.(figField).sourcePath = string(assetInfos(k).sourcePath);
        groupData.(figField).assetType = string(assetInfos(k).assetType);
        groupData.(figField).importReport = string(assetInfos(k).importReport);
    else
        groupData.(figField).sourcePath = "";
        groupData.(figField).assetType = "";
        groupData.(figField).importReport = "";
    end

    if k <= numel(axesList) && isgraphics(axesList(k))
        [items, mapRows] = extractAxesItems(axesList(k), panels(k), figField);
        names = fieldnames(items);
        for n = 1:numel(names)
            groupData.(figField).(names{n}) = items.(names{n});
        end
        groupData.panelMap = [groupData.panelMap; mapRows(:)];
    end
end
end

function [items, mapRows] = extractAxesItems(ax, panel, figField)
items = struct();
mapRows = struct('figField', {}, 'panelId', {}, 'panelLabel', {}, ...
    'objectType', {}, 'displayName', {}, 'fieldName', {});

objects = [findobj(ax, 'Type', 'line'); ...
           findobj(ax, 'Type', 'scatter'); ...
           findobj(ax, 'Type', 'bar'); ...
           findobj(ax, 'Type', 'errorbar'); ...
           findobj(ax, 'Type', 'image'); ...
           findobj(ax, 'Type', 'surface')];
objects = flipud(objects(:));

legendCounter = 0;
used = strings(0);
for i = 1:numel(objects)
    h = objects(i);
    if ~isgraphics(h)
        continue
    end
    legendCounter = legendCounter + 1;
    displayName = getDisplayName(h, legendCounter);
    fieldName = gfc.safeFieldName(displayName, 'legend', legendCounter);
    while any(used == string(fieldName))
        legendCounter = legendCounter + 1;
        fieldName = sprintf('legend_%03d', legendCounter);
    end
    used(end + 1) = string(fieldName); %#ok<AGROW>

    item = objectData(h);
    item.name = string(displayName);
    item.panelLabel = string(panel.label);
    item.panelId = panel.id;
    item.objectType = string(class(h));
    items.(fieldName) = item;

    mapRows(end + 1) = struct('figField', string(figField), ...
        'panelId', panel.id, ...
        'panelLabel', string(panel.label), ...
        'objectType', string(class(h)), ...
        'displayName', string(displayName), ...
        'fieldName', string(fieldName)); %#ok<AGROW>
end
end

function name = getDisplayName(h, idx)
name = '';
try
    name = char(h.DisplayName);
catch
end
if isempty(name) || startsWith(name, '_')
    name = sprintf('图例%d', idx);
end
end

function item = objectData(h)
item = struct();
try
    item.x = h.XData;
catch
end
try
    item.y = h.YData;
catch
end
try
    item.z = h.ZData;
catch
end
try
    item.c = h.CData;
catch
end
try
    item.size = h.SizeData;
catch
end
try
    item.color = h.Color;
catch
end
try
    item.lineWidth = h.LineWidth;
catch
end
try
    item.marker = string(h.Marker);
catch
end
try
    item.cdata = h.CData;
catch
end
try
    item.alphaData = h.AlphaData;
catch
end
try
    ax = ancestor(h, 'axes');
    item.xlim = ax.XLim;
    item.ylim = ax.YLim;
    item.clim = ax.CLim;
    item.colormap = colormap(ax);
catch
end
end
