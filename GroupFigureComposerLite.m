function result = GroupFigureComposerLite(files, outputFile, opts)
%GROUPFIGURECOMPOSERLITE Compose figure/image files into a publication panel.
%
% Example:
%   files = ["a.fig", "b.svg", "c.png"];
%   GroupFigureComposerLite(files, "composite.png", Rows=1, Cols=3);

arguments
    files = string.empty(1, 0)
    outputFile (1,:) char = ''
    opts.Rows double = []
    opts.Cols double = []
    opts.WidthPx (1,1) double {mustBePositive} = 1200
    opts.HeightPx (1,1) double {mustBePositive} = 900
    opts.DPI (1,1) double {mustBePositive} = 300
    opts.FontName (1,:) char = 'Arial'
    opts.FontSize (1,1) double {mustBePositive} = 9
    opts.Visible (1,:) char = 'off'
end

files = string(files);
if isempty(files)
    error('gfc:Lite:NoFiles', 'Provide at least one FIG, SVG, or raster image file.');
end

n = numel(files);
rows = opts.Rows;
cols = opts.Cols;
if isempty(rows) && isempty(cols)
    cols = ceil(sqrt(n));
    rows = ceil(n / cols);
elseif isempty(rows)
    rows = ceil(n / cols);
elseif isempty(cols)
    cols = ceil(n / rows);
end
rows = max(1, round(rows));
cols = max(1, round(cols));
if rows * cols < n
    error('gfc:Lite:GridTooSmall', 'Rows * Cols must be at least the number of files.');
end

panels = gfc.createPanels(rows, cols);
panels = panels(1:n);
sourceFig = figure('Visible', 'off', 'Color', 'w');
cleanupSource = onCleanup(@() close(sourceFig));
axesList = gobjects(1, n);
reports = strings(1, n);
for k = 1:n
    ax = axes(sourceFig); %#ok<LAXES>
    axesList(k) = ax;
    reports(k) = importLiteFile(ax, char(files(k)));
    panels(k).sourcePath = char(files(k));
end
gfc.styleAxes(axesList, 'FontName', opts.FontName, 'FontSize', opts.FontSize, ...
    'LineWidth', 1, 'ApplyChildLineWidth', false);

fig = gfc.renderCompositeFigure(panels, axesList, 'Rows', rows, 'Cols', cols, ...
    'Visible', opts.Visible, 'WidthPx', opts.WidthPx, 'HeightPx', opts.HeightPx, ...
    'LabelFontName', opts.FontName, 'LabelFontSize', opts.FontSize + 2);

if strlength(string(outputFile)) > 0
    gfc.exportComposite(fig, outputFile, 'DPI', opts.DPI);
end

result = struct('figure', fig, 'reports', reports, 'rows', rows, 'cols', cols);
if nargout == 0 && strcmp(opts.Visible, 'off')
    close(fig);
    clear result
end
end

function report = importLiteFile(ax, filename)
[~, ~, ext] = fileparts(filename);
switch lower(ext)
    case '.fig'
        report = gfc.importFigToAxes(ax, filename);
    case '.svg'
        report = gfc.importSvgToAxes(ax, filename, 'AllowInkscapeFallback', true);
    case {'.png', '.jpg', '.jpeg', '.tif', '.tiff', '.bmp'}
        report = gfc.importRasterToAxes(ax, filename, 'AutoCrop', true);
    otherwise
        error('gfc:Lite:UnsupportedFile', 'Unsupported file type: %s', ext);
end
end
