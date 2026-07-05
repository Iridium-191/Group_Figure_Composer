function lgd = addStyledLegend(ax, opts)
%ADDSTYLEDLEGEND Create a legend with consistent font styling.

arguments
    ax
    opts.FontName (1,:) char = 'Arial'
    opts.FontSize (1,1) double {mustBePositive} = 9
    opts.Objects = []
end

if isempty(opts.Objects)
    objects = gfc.legendObjects(ax);
else
    objects = opts.Objects(:);
    objects = objects(isgraphics(objects));
end
if isempty(objects)
    error('gfc:addStyledLegend:NoObjects', '当前 axes 中没有可加入图例的数据对象。');
end

names = strings(1, numel(objects));
for k = 1:numel(objects)
    try
        name = string(objects(k).DisplayName);
    catch
        name = "";
    end
    if strlength(name) == 0 || startsWith(name, "_")
        name = "data" + k;
        try
            objects(k).DisplayName = char(name);
        catch
        end
    end
    names(k) = name;
end

lgd = legend(ax, objects, cellstr(names), 'Interpreter', 'none', ...
    'Location', 'best');
lgd.FontName = opts.FontName;
lgd.FontSize = opts.FontSize;
try
    lgd.Box = 'on';
catch
end
end
