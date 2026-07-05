function report = importRasterToAxes(ax, filename, opts)
%IMPORTRASTERTOAXES Read, crop, and display a raster image in an axes.

arguments
    ax
    filename (1,:) char
    opts.AutoCrop (1,1) logical = true
end

[img, ~, alpha] = imread(filename);
if ~isempty(alpha)
    img = cat(3, img, alpha);
end

rect = [1 1 size(img, 2) size(img, 1)];
if opts.AutoCrop
    [img, rect] = gfc.cropRaster(img);
end

cla(ax);
if size(img, 3) == 4
    h = image(ax, img(:, :, 1:3));
    h.AlphaData = im2double(img(:, :, 4));
else
    image(ax, img);
end
axis(ax, 'image');
axis(ax, 'off');
set(ax, 'YDir', 'reverse');
report = sprintf('Raster imported. Crop rect [x y w h] = [%g %g %g %g].', rect);
end
