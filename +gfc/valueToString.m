function s = valueToString(v)
%VALUETOSTRING Compact property value formatting for the property table.

if isstring(v)
    s = char(v);
elseif ischar(v)
    s = v;
elseif isnumeric(v) || islogical(v)
    if isscalar(v)
        s = num2str(v);
    else
        s = mat2str(v, 5);
    end
else
    try
        s = char(v);
    catch
        s = '<unsupported>';
    end
end
end
