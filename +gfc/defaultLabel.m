function label = defaultLabel(index)
%DEFAULTLABEL Return spreadsheet-style panel labels: a..z, aa..az.

arguments
    index (1,1) double {mustBeInteger,mustBePositive}
end

letters = 'abcdefghijklmnopqrstuvwxyz';
label = "";
n = index;
while n > 0
    r = mod(n - 1, 26) + 1;
    label = string(letters(r)) + label;
    n = floor((n - 1) / 26);
end
label = char(label);
end
