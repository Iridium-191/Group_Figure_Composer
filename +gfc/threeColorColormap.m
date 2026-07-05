function cmap = threeColorColormap(colors, n)
%THREECOLORCOLORMAP Interpolate three RGB colors into a continuous colormap.

arguments
    colors (3,3) double
    n (1,1) double {mustBeInteger,mustBePositive} = 256
end

cmap = gfc.controlPointColormap(colors, [0; 0.5; 1], n);
end
