function [cropped, rect, mask] = cropRaster(img, opts)
%CROPRASTER Trim transparent or near-white margins from raster images.

arguments
    img
    opts.WhiteTolerance (1,1) double {mustBeGreaterThanOrEqual(opts.WhiteTolerance,0),mustBeLessThanOrEqual(opts.WhiteTolerance,1)} = 0.985
    opts.Padding (1,1) double {mustBeInteger,mustBeNonnegative} = 4
end

if isempty(img)
    cropped = img;
    rect = [1 1 0 0];
    mask = false(0);
    return
end

imgd = im2double(img);
if ismatrix(imgd)
    nonWhite = imgd < opts.WhiteTolerance;
else
    rgb = imgd(:, :, 1:min(3, size(imgd, 3)));
    nonWhite = any(rgb < opts.WhiteTolerance, 3);
    if size(imgd, 3) == 4
        nonWhite = nonWhite | imgd(:, :, 4) > 0.01;
    end
end

mask = bwareaopen(nonWhite, 8);
if ~any(mask(:))
    cropped = img;
    rect = [1 1 size(img, 2) size(img, 1)];
    return
end

[r, c] = find(mask);
r1 = max(1, min(r) - opts.Padding);
r2 = min(size(img, 1), max(r) + opts.Padding);
c1 = max(1, min(c) - opts.Padding);
c2 = min(size(img, 2), max(c) + opts.Padding);
cropped = img(r1:r2, c1:c2, :);
rect = [c1, r1, c2 - c1 + 1, r2 - r1 + 1];
end
