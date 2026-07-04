function objects = legendObjects(ax)
%LEGENDOBJECTS Return visible graphics objects that can appear in a legend.

types = {'line','scatter','bar','errorbar','patch','surface','image'};
objects = gobjects(0);
for i = 1:numel(types)
    found = findobj(ax, 'Type', types{i});
    if ~isempty(found)
        objects = [objects; flipud(found(:))]; %#ok<AGROW>
    end
end

keep = false(size(objects));
for k = 1:numel(objects)
    try
        keep(k) = strcmp(objects(k).Visible, 'on') && ~strcmp(objects(k).HandleVisibility, 'off');
    catch
        keep(k) = true;
    end
end
objects = objects(keep);
end
