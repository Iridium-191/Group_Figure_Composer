function report = importSvgToAxes(ax, filename, opts)
%IMPORTSVGTOAXES Parse common SVG shapes; optionally rasterize fallback.

arguments
    ax
    filename (1,:) char
    opts.AllowInkscapeFallback (1,1) logical = true
end

cla(ax);
axis(ax, 'equal');
axis(ax, 'off');
hold(ax, 'on');

doc = xmlread(filename);
root = doc.getDocumentElement();
[viewBox, width, height] = readViewBox(root);
parsed = 0;
unsupported = 0;

nodes = root.getElementsByTagName('*');
for i = 0:nodes.getLength - 1
    node = nodes.item(i);
    tag = char(node.getNodeName);
    try
        switch lower(tag)
            case 'line'
                parsed = parsed + drawLine(ax, node);
            case 'rect'
                parsed = parsed + drawRect(ax, node);
            case 'circle'
                parsed = parsed + drawCircle(ax, node);
            case 'ellipse'
                parsed = parsed + drawEllipse(ax, node);
            case {'polyline','polygon'}
                parsed = parsed + drawPoly(ax, node, strcmpi(tag, 'polygon'));
            case 'path'
                parsed = parsed + drawSimplePath(ax, node);
            case 'text'
                parsed = parsed + drawText(ax, node);
            otherwise
                if ismember(lower(tag), {'image','defs','clipPath','mask','pattern','filter','linearGradient','radialGradient'})
                    unsupported = unsupported + 1;
                end
        end
    catch
        unsupported = unsupported + 1;
    end
end

if parsed == 0 && opts.AllowInkscapeFallback
    exe = gfc.checkInkscape();
    if ~isempty(exe)
        pngFile = [tempname, '.png'];
        cmd = sprintf('"%s" "%s" --export-type=png --export-filename="%s"', exe, filename, pngFile);
        status = system(cmd);
        if status == 0 && isfile(pngFile)
            report = gfc.importRasterToAxes(ax, pngFile);
            delete(pngFile);
            report = sprintf('SVG rasterized by Inkscape. %s', report);
            return
        end
    end
end

if ~isempty(viewBox)
    xlim(ax, [viewBox(1), viewBox(1) + viewBox(3)]);
    ylim(ax, [viewBox(2), viewBox(2) + viewBox(4)]);
else
    xlim(ax, [0 width]);
    ylim(ax, [0 height]);
end
set(ax, 'YDir', 'reverse');
hold(ax, 'off');
report = sprintf('SVG parsed. %d supported elements drawn; %d complex elements skipped.', parsed, unsupported);
end

function [viewBox, width, height] = readViewBox(root)
viewBox = [];
width = readNumber(root, 'width', 100);
height = readNumber(root, 'height', 100);
vb = char(root.getAttribute('viewBox'));
if ~isempty(vb)
    vals = sscanf(vb, '%f');
    if numel(vals) == 4
        viewBox = vals(:).';
        width = viewBox(3);
        height = viewBox(4);
    end
end
end

function n = drawLine(ax, node)
x1 = readNumber(node, 'x1', 0); y1 = readNumber(node, 'y1', 0);
x2 = readNumber(node, 'x2', 0); y2 = readNumber(node, 'y2', 0);
args = lineArgs(node);
line(ax, [x1 x2], [y1 y2], args{:});
n = 1;
end

function n = drawRect(ax, node)
x = readNumber(node, 'x', 0); y = readNumber(node, 'y', 0);
w = readNumber(node, 'width', 0); h = readNumber(node, 'height', 0);
args = shapeArgs(node);
rectangle(ax, 'Position', [x y w h], args{:});
n = 1;
end

function n = drawCircle(ax, node)
cx = readNumber(node, 'cx', 0); cy = readNumber(node, 'cy', 0); r = readNumber(node, 'r', 0);
args = shapeArgs(node);
rectangle(ax, 'Position', [cx-r cy-r 2*r 2*r], 'Curvature', [1 1], args{:});
n = 1;
end

function n = drawEllipse(ax, node)
cx = readNumber(node, 'cx', 0); cy = readNumber(node, 'cy', 0);
rx = readNumber(node, 'rx', 0); ry = readNumber(node, 'ry', 0);
args = shapeArgs(node);
rectangle(ax, 'Position', [cx-rx cy-ry 2*rx 2*ry], 'Curvature', [1 1], args{:});
n = 1;
end

function n = drawPoly(ax, node, closed)
points = char(node.getAttribute('points'));
vals = sscanf(regexprep(points, '[,\s]+', ' '), '%f');
if numel(vals) < 4
    n = 0;
    return
end
xy = reshape(vals, 2, []).';
if closed
    patch(ax, xy(:,1), xy(:,2), readFill(node), 'EdgeColor', readStroke(node), 'LineWidth', readStrokeWidth(node));
else
    args = lineArgs(node);
    line(ax, xy(:,1), xy(:,2), args{:});
end
n = 1;
end

function n = drawSimplePath(ax, node)
d = char(node.getAttribute('d'));
tokens = regexp(d, '([MLZmlz])|([-+]?\d*\.?\d+(?:[eE][-+]?\d+)?)', 'match');
xy = [];
cmd = '';
k = 1;
while k <= numel(tokens)
    t = tokens{k};
    if any(strcmp(t, {'M','L','Z','m','l','z'}))
        cmd = t;
        k = k + 1;
        continue
    end
    if isempty(cmd) || any(strcmp(cmd, {'Z','z'})) || k == numel(tokens)
        k = k + 1;
        continue
    end
    x = str2double(tokens{k});
    y = str2double(tokens{k + 1});
    xy(end + 1, :) = [x y]; %#ok<AGROW>
    k = k + 2;
end
if size(xy, 1) < 2
    n = 0;
    return
end
args = lineArgs(node);
line(ax, xy(:,1), xy(:,2), args{:});
n = 1;
end

function n = drawText(ax, node)
x = readNumber(node, 'x', 0); y = readNumber(node, 'y', 0);
str = strtrim(char(node.getTextContent));
if isempty(str)
    n = 0;
    return
end
text(ax, x, y, str, 'Interpreter', 'none', 'Color', readFill(node), 'FontSize', readNumber(node, 'font-size', 10));
n = 1;
end

function args = lineArgs(node)
args = {'Color', readStroke(node), 'LineWidth', readStrokeWidth(node)};
end

function args = shapeArgs(node)
args = {'EdgeColor', readStroke(node), 'LineWidth', readStrokeWidth(node), ...
    'FaceColor', readFill(node)};
end

function val = readNumber(node, attr, default)
s = char(node.getAttribute(attr));
if isempty(s)
    styleVal = readStyle(node, attr);
    s = styleVal;
end
s = regexprep(s, '[a-zA-Z%]+$', '');
val = str2double(s);
if isnan(val)
    val = default;
end
end

function color = readStroke(node)
color = readColor(readAttrOrStyle(node, 'stroke', '#000000'), [0 0 0]);
end

function color = readFill(node)
s = readAttrOrStyle(node, 'fill', 'none');
if strcmpi(s, 'none') || isempty(s)
    color = 'none';
else
    color = readColor(s, [1 1 1]);
end
end

function w = readStrokeWidth(node)
w = readNumber(node, 'stroke-width', 1);
end

function s = readAttrOrStyle(node, attr, default)
s = char(node.getAttribute(attr));
if isempty(s)
    s = readStyle(node, attr);
end
if isempty(s)
    s = default;
end
end

function s = readStyle(node, attr)
s = '';
style = char(node.getAttribute('style'));
if isempty(style)
    return
end
m = regexp(style, [attr '\s*:\s*([^;]+)'], 'tokens', 'once');
if ~isempty(m)
    s = strtrim(m{1});
end
end

function rgb = readColor(s, default)
s = strtrim(char(s));
if startsWith(s, '#') && (numel(s) == 7 || numel(s) == 4)
    if numel(s) == 4
        s = ['#' s(2) s(2) s(3) s(3) s(4) s(4)];
    end
    rgb = [hex2dec(s(2:3)), hex2dec(s(4:5)), hex2dec(s(6:7))] / 255;
elseif startsWith(lower(s), 'rgb')
    vals = sscanf(regexprep(s, '[^\d\.\s,]', ''), '%f,');
    if numel(vals) < 3
        vals = sscanf(regexprep(s, '[^\d\.\s]', ' '), '%f');
    end
    rgb = vals(1:3).' / 255;
elseif any(strcmpi(s, {'red','green','blue','black','white','yellow','cyan','magenta'}))
    rgb = s;
else
    rgb = default;
end
end
