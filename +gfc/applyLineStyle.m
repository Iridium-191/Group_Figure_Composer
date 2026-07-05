function changed = applyLineStyle(handles, opts)
%APPLYLINESTYLE Apply line style and width to graphics handles when possible.

arguments
    handles
    opts.LineStyle (1,:) char = ''
    opts.LineWidth (1,1) double = NaN
end

validStyles = {'-','--',':','-.','none'};
lineStyle = char(opts.LineStyle);
if ~isempty(lineStyle) && ~any(strcmp(lineStyle, validStyles))
    error('gfc:applyLineStyle:InvalidLineStyle', 'Unsupported line style: %s', lineStyle);
end

changed = 0;
for h = reshape(handles, 1, [])
    if isempty(h) || ~isgraphics(h)
        continue
    end
    touched = false;
    if ~isempty(lineStyle) && isprop(h, 'LineStyle')
        try
            h.LineStyle = lineStyle;
            touched = true;
        catch
        end
    end
    if isfinite(opts.LineWidth) && opts.LineWidth > 0 && isprop(h, 'LineWidth')
        try
            h.LineWidth = opts.LineWidth;
            touched = true;
        catch
        end
    end
    if touched
        changed = changed + 1;
    end
end
end
