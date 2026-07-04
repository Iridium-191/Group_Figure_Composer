function palette = paletteFromImage(filename, nColors)
%PALETTEFROMIMAGE Extract representative colors from an image.

arguments
    filename (1,:) char
    nColors (1,1) double {mustBeInteger,mustBePositive} = 6
end

img = im2double(imread(filename));
if ismatrix(img)
    img = repmat(img, 1, 1, 3);
end
rgb = reshape(img(:, :, 1:3), [], 3);
rgb = rgb(all(isfinite(rgb), 2), :);
if size(rgb, 1) > 5000
    rgb = rgb(round(linspace(1, size(rgb, 1), 5000)), :);
end
[~, palette] = kmeans(rgb, min(nColors, size(rgb, 1)), 'Replicates', 3, 'MaxIter', 200);
[~, order] = sort(sum(palette, 2), 'descend');
palette = palette(order, :);
end
