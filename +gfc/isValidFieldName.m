function tf = isValidFieldName(name)
%ISVALIDFIELDNAME True when NAME can be accessed as S.name in MATLAB.

if isstring(name)
    name = char(name);
end
tf = ischar(name) && isvarname(name) && all(name <= char(127));
end
