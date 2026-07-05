function styleAxes(axesList, opts)
%STYLEAXES Apply a shared publication style to axes and children.

arguments
    axesList
    opts.FontName (1,:) char = 'Arial'
    opts.FontSize (1,1) double {mustBePositive} = 9
    opts.LineWidth (1,1) double {mustBePositive} = 1
    opts.Box (1,:) char = 'on'
    opts.TickDir (1,:) char {mustBeMember(opts.TickDir, {'in','out','both','none'})} = 'in'
    opts.ApplyChildLineWidth (1,1) logical = true
end

axesList = axesList(isgraphics(axesList));
for ax = reshape(axesList, 1, [])
    try
        set(ax, 'FontName', opts.FontName, 'FontSize', opts.FontSize, ...
            'LineWidth', opts.LineWidth, 'Box', opts.Box, 'TickDir', opts.TickDir);
    catch
    end
    setRulerObject(ax.XAxis, opts.FontName, opts.FontSize);
    setRulerObject(ax.YAxis, opts.FontName, opts.FontSize);
    setRulerObject(ax.ZAxis, opts.FontName, opts.FontSize);
    setTextObject(ax.Title, opts.FontName, opts.FontSize);
    setTextObject(ax.XLabel, opts.FontName, opts.FontSize);
    setTextObject(ax.YLabel, opts.FontName, opts.FontSize);
    setTextObject(ax.ZLabel, opts.FontName, opts.FontSize);

    if opts.ApplyChildLineWidth
        lines = findobj(ax, 'Type', 'line');
        setIfPossible(lines, 'LineWidth', opts.LineWidth);
        scatters = findobj(ax, 'Type', 'scatter');
        setIfPossible(scatters, 'LineWidth', opts.LineWidth);
    end
    texts = findall(ax, 'Type', 'text');
    setIfPossible(texts, 'FontName', opts.FontName);
    setIfPossible(texts, 'FontSize', opts.FontSize);

    parentFig = ancestor(ax, 'figure');
    legends = findall(parentFig, 'Type', 'legend');
    legends = legends(arrayfun(@(h) isOwnedByAxes(h, ax), legends));
    setIfPossible(legends, 'FontName', opts.FontName);
    setIfPossible(legends, 'FontSize', opts.FontSize);
    colorbars = findall(parentFig, 'Type', 'colorbar');
    colorbars = colorbars(arrayfun(@(h) isOwnedByAxes(h, ax), colorbars));
    setIfPossible(colorbars, 'FontName', opts.FontName);
    setIfPossible(colorbars, 'FontSize', opts.FontSize);
    for cb = reshape(colorbars, 1, [])
        try
            setTextObject(cb.Label, opts.FontName, opts.FontSize);
        catch
        end
    end
end
end

function setTextObject(h, fontName, fontSize)
try
    h.FontName = fontName;
    h.FontSize = fontSize;
catch
end
end

function setRulerObject(h, fontName, fontSize)
try
    h.FontName = fontName;
catch
end
try
    h.FontSize = fontSize;
catch
end
end

function setIfPossible(handles, prop, value)
for h = reshape(handles, 1, [])
    try
        h.(prop) = value;
    catch
    end
end
end

function tf = isOwnedByAxes(h, ax)
tf = false;
try
    tf = isequal(h.Axes, ax);
catch
end
end
