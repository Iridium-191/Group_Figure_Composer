function result = GroupFigureComposerEN(files, outputFile, opts)
%GROUPFIGURECOMPOSEREN English command-style group figure composer.
%
% This English entry point is designed for GitHub/publication workflows. It
% composes MATLAB FIG, SVG, and raster image files into a multi-panel figure.
%
% Example:
%   files = ["panel_a.fig", "panel_b.svg", "panel_c.png"];
%   GroupFigureComposerEN(files, "composite.png", ...
%       Rows=1, Cols=3, WidthPx=1800, HeightPx=650, DPI=300);
%
% Run the demo:
%   run("examples/demo_lite.m")
%
% For the full Chinese interactive GUI, use:
%   GroupFigureComposerCN

arguments
    files = string.empty(1, 0)
    outputFile = ""
    opts.Rows double = []
    opts.Cols double = []
    opts.WidthPx (1,1) double {mustBePositive} = 1200
    opts.HeightPx (1,1) double {mustBePositive} = 900
    opts.DPI (1,1) double {mustBePositive} = 300
    opts.FontName (1,:) char = 'Arial'
    opts.FontSize (1,1) double {mustBePositive} = 9
    opts.Visible (1,:) char = 'off'
end

if isempty(files)
    help GroupFigureComposerEN
    if nargout > 0
        result = struct();
    end
    return
end

result = GroupFigureComposerLite(files, outputFile, ...
    Rows=opts.Rows, Cols=opts.Cols, WidthPx=opts.WidthPx, ...
    HeightPx=opts.HeightPx, DPI=opts.DPI, FontName=opts.FontName, ...
    FontSize=opts.FontSize, Visible=opts.Visible);
end
