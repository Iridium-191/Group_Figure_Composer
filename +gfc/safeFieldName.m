function fieldName = safeFieldName(name, fallbackPrefix, index)
%SAFEFIELDNAME Create an ASCII MATLAB struct field name.

arguments
    name
    fallbackPrefix (1,:) char = 'item'
    index (1,1) double {mustBeInteger,mustBePositive} = 1
end

if isstring(name)
    name = char(name);
end

if gfc.isValidFieldName(name)
    fieldName = name;
    return
end

fieldName = sprintf('%s_%03d', fallbackPrefix, index);
end
