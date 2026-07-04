function changed = applyObjectColor(h, rgb)
%APPLYOBJECTCOLOR Apply RGB to the most relevant color properties.

arguments
    h
    rgb (1,3) double {mustBeGreaterThanOrEqual(rgb,0),mustBeLessThanOrEqual(rgb,1)}
end

changed = false;
if isempty(h) || ~isgraphics(h)
    return
end

if isprop(h, 'Color')
    changed = setProp(h, 'Color', rgb) || changed;
end

if isprop(h, 'MarkerEdgeColor')
    changed = setProp(h, 'MarkerEdgeColor', rgb) || changed;
end
if isprop(h, 'MarkerFaceColor')
    changed = setProp(h, 'MarkerFaceColor', rgb) || changed;
end

if isprop(h, 'EdgeColor')
    changed = setProp(h, 'EdgeColor', rgb) || changed;
end
if isprop(h, 'FaceColor')
    try
        current = h.FaceColor;
        if ~(ischar(current) || isstring(current)) || ~strcmpi(string(current), "none")
            changed = setProp(h, 'FaceColor', rgb) || changed;
        end
    catch
        changed = setProp(h, 'FaceColor', rgb) || changed;
    end
end
end

function ok = setProp(h, prop, value)
ok = false;
try
    h.(prop) = value;
    ok = true;
catch
end
end
