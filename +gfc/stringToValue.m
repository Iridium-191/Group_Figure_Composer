function v = stringToValue(s, oldValue)
%STRINGTOVALUE Parse property table text using the existing value as hint.

if isstring(s)
    s = char(s);
end

if isnumeric(oldValue) || islogical(oldValue)
    parsed = str2num(s); %#ok<ST2NM>
    if ~isempty(parsed)
        v = parsed;
    else
        v = oldValue;
    end
elseif isstring(oldValue)
    v = string(s);
else
    v = s;
end
end
