function changed = applyPalette(target, palette, mode, opts)
%APPLYPALETTE Recolor selected objects or line objects from a palette.

arguments
    target
    palette (:,3) double {mustBeGreaterThanOrEqual(palette,0),mustBeLessThanOrEqual(palette,1)}
    mode (1,:) char {mustBeMember(mode, {'order','nearest'})} = 'order'
    opts.Target (1,:) char {mustBeMember(opts.Target, {'selected','panel','allLines','all'})} = 'allLines'
    opts.Selected = []
end

objects = collectObjects(target, opts.Target, opts.Selected);
if isempty(objects) || isempty(palette)
    changed = 0;
    return
end

changed = 0;
for k = 1:numel(objects)
    h = objects(k);
    try
        current = currentColor(h);
        if strcmp(mode, 'nearest') && isnumeric(current) && numel(current) == 3
            [~, idx] = min(sum((palette - current(:).').^2, 2));
        else
            idx = mod(k - 1, size(palette, 1)) + 1;
        end
        changed = changed + gfc.applyObjectColor(h, palette(idx, :));
    catch
    end
end
end

function objects = collectObjects(target, targetMode, selected)
objects = [];
switch targetMode
    case 'selected'
        if ~isempty(selected)
            objects = selected;
        else
            objects = target;
        end
    case 'allLines'
        axesList = targetAxes(target);
        for ax = reshape(axesList, 1, [])
            if isgraphics(ax)
                lines = findobj(ax, 'Type', 'line');
                objects = [objects; lines(:)]; %#ok<AGROW>
            end
        end
    case 'panel'
        axesList = targetAxes(target);
        for ax = reshape(axesList, 1, [])
            if isgraphics(ax)
                objects = [objects; colorObjectsInAxes(ax)]; %#ok<AGROW>
            end
        end
    case 'all'
        axesList = targetAxes(target);
        for ax = reshape(axesList, 1, [])
            if isgraphics(ax)
                objects = [objects; colorObjectsInAxes(ax)]; %#ok<AGROW>
            end
        end
end
objects = flipud(objects(:));
objects = objects(isgraphics(objects));
end

function axesList = targetAxes(target)
axesList = gobjects(0);
for h = reshape(target, 1, [])
    if ~isgraphics(h)
        continue
    end
    if isa(h, 'matlab.graphics.axis.Axes') || isa(h, 'matlab.ui.control.UIAxes')
        axesList(end + 1) = h; %#ok<AGROW>
    else
        ax = ancestor(h, 'axes');
        if ~isempty(ax) && isgraphics(ax)
            axesList(end + 1) = ax; %#ok<AGROW>
        end
    end
end
end

function objects = colorObjectsInAxes(ax)
objects = [ ...
    findobj(ax, 'Type', 'line'); ...
    findobj(ax, 'Type', 'scatter'); ...
    findobj(ax, 'Type', 'text'); ...
    findobj(ax, 'Type', 'rectangle'); ...
    findobj(ax, 'Type', 'patch')];
end

function rgb = currentColor(h)
rgb = [];
props = {'Color','MarkerFaceColor','MarkerEdgeColor','EdgeColor','FaceColor'};
for k = 1:numel(props)
    if isprop(h, props{k})
        try
            value = h.(props{k});
            if isnumeric(value) && numel(value) == 3
                rgb = value;
                return
            end
        catch
        end
    end
end
end
