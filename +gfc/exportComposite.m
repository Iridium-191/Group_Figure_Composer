function exportComposite(fig, filename, opts)
%EXPORTCOMPOSITE Export an export-ready figure to common formats.

arguments
    fig
    filename (1,:) char
    opts.DPI (1,1) double {mustBeInteger,mustBePositive} = 300
end

[~, ~, ext] = fileparts(filename);
ext = lower(ext);
switch ext
    case '.fig'
        savefig(fig, filename);
    case {'.png', '.tif', '.tiff', '.pdf'}
        exportgraphics(fig, filename, 'Resolution', opts.DPI, 'BackgroundColor', 'white');
    case '.svg'
        print(fig, filename, '-dsvg', sprintf('-r%d', opts.DPI));
    otherwise
        error('gfc:exportComposite:UnsupportedFormat', '不支持的导出格式: %s', ext);
end
end
