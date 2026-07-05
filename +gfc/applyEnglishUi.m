function applyEnglishUi(app, installCallbackWrappers)
%APPLYENGLISHUI Translate the interactive GUI shell to English.
%
% This function intentionally leaves the core Chinese app implementation in
% place and translates the visible UI shell after construction. It is used by
% GroupFigureComposerGUI_EN so the English GUI can share the mature editing
% logic with the Chinese GUI.

if nargin < 2
    installCallbackWrappers = true;
end
if isempty(app) || ~isprop(app, 'UIFigure') || isempty(app.UIFigure) || ~isvalid(app.UIFigure)
    return
end

translateFigure(app.UIFigure);
translateComponents(app.UIFigure);
translateKnownProperties(app);
if installCallbackWrappers
    installWrappers(app);
end
drawnow limitrate
end

function translateFigure(fig)
try
    fig.Name = translateText(fig.Name);
catch
end
end

function translateComponents(root)
components = findall(root);
for k = 1:numel(components)
    h = components(k);
    translateStringProperty(h, 'Text');
    translateStringProperty(h, 'Title');
    translateStringProperty(h, 'Name');
    translateItemsProperty(h);
    translateColumnNames(h);
end
end

function translateKnownProperties(app)
try
    app.UIFigure.Name = 'Group Figure Composer';
catch
end
try
    app.LeftPanel.Title = 'Workflow';
catch
end
try
    app.CanvasPanel.Title = 'Canvas';
catch
end
try
    app.RightPanel.Title = 'Objects and Properties';
catch
end
try
    app.PropertyTable.ColumnName = {'Property','Value'};
catch
end
try
    if isvalid(app.SnapSwitch)
        oldValue = string(app.SnapSwitch.Value);
        app.SnapSwitch.Items = {'Off','On'};
        if oldValue == "开" || oldValue == "On"
            app.SnapSwitch.Value = 'On';
        else
            app.SnapSwitch.Value = 'Off';
        end
    end
catch
end
try
    app.StatusLabel.Text = translateStatus(app.StatusLabel.Text);
catch
end
end

function translateStringProperty(h, prop)
try
    value = h.(prop);
    if ischar(value) || isstring(value)
        h.(prop) = char(translateText(string(value)));
    end
catch
end
end

function translateItemsProperty(h)
try
    if isa(h, 'matlab.ui.control.Switch')
        return
    end
    items = string(h.Items);
    if isempty(items)
        return
    end
    translated = arrayfun(@translateText, items, 'UniformOutput', false);
    h.Items = cellfun(@char, translated, 'UniformOutput', false);
    try
        value = string(h.Value);
        newValue = translateText(value);
        if any(strcmp(char(newValue), h.Items))
            h.Value = char(newValue);
        end
    catch
    end
catch
end
end

function translateColumnNames(h)
try
    names = string(h.ColumnName);
    if isempty(names)
        return
    end
    translated = arrayfun(@translateText, names, 'UniformOutput', false);
    h.ColumnName = cellfun(@char, translated, 'UniformOutput', false);
catch
end
end

function installWrappers(app)
fig = app.UIFigure;
try
    state = fig.UserData;
    if isstruct(state) && isfield(state, 'gfcEnglishUiWrapped') && state.gfcEnglishUiWrapped
        return
    end
catch
    state = struct();
end

components = findall(fig);
props = {'ButtonPushedFcn','ValueChangedFcn','CellEditCallback', ...
    'SelectionChangedFcn','MenuSelectedFcn'};
for k = 1:numel(components)
    h = components(k);
    for p = 1:numel(props)
        wrapCallback(h, props{p}, app);
    end
end

if ~isstruct(state)
    state = struct('PreviousUserData', state);
end
state.gfcEnglishUiWrapped = true;
try
    fig.UserData = state;
catch
end
end

function wrapCallback(h, prop, app)
try
    original = h.(prop);
catch
    return
end
if isempty(original) || ~isa(original, 'function_handle')
    return
end
marker = ['gfcEnglishUiOriginal_' prop];
try
    if isappdata(h, marker)
        return
    end
    setappdata(h, marker, original);
    h.(prop) = @(src, event) invokeAndTranslate(src, event, app, original);
catch
end
end

function invokeAndTranslate(src, event, app, callback)
try
    callback(src, event);
catch ME
    gfc.applyEnglishUi(app, false);
    rethrow(ME)
end
gfc.applyEnglishUi(app, false);
end

function out = translateStatus(value)
out = translateText(string(value));
if out == string(value)
    if contains(string(value), "未检测到 Inkscape")
        out = "Ready. Inkscape was not detected; complex SVG files will report parser details.";
    elseif contains(string(value), "Inkscape")
        out = regexprep(string(value), "^已启动。", "Ready. ");
    end
end
end

function out = translateText(value)
value = string(value);
dict = translationMap();
key = char(value);
if isKey(dict, key)
    out = string(dict(key));
    return
end

out = value;
if startsWith(value, "Panel ")
    out = value;
elseif value == "组图项目"
    out = "Project";
elseif startsWith(value, "已启动。")
    out = translateStatus(value);
end
end

function dict = translationMap()
persistent map
if isempty(map)
    keys = { ...
        '组图工具 Group Figure Composer', '流程', '画布', '对象与属性', ...
        '1 布局', '2 导入', '3 精修', '4 预览导出', '高级', ...
        '画布尺寸', '行数', '列数', '画布宽 px', '画布高 px', ...
        'Panel 间距', '页面边距', '新建布局', '合并区域', ...
        '起始行', '起始列', '跨行', '跨列', '合并', '取消合并', ...
        '素材导入', '导入到选中 panel', '统一字体', '字体', '字号', ...
        '统一框线/字体', '自动对齐绘图区框线', ...
        '支持 FIG / SVG / PNG / JPG / TIF / BMP。空 panel 中的 + 也可以直接导入。', ...
        'Panel 编号', '编号', '格式', '应用编号', ...
        '色卡', '内置', '导入色卡', '应用到选中', '所有谱线', ...
        'Map Colormap', 'Colormap', '反转', '应用到当前 axes', '应用到当前 panel', ...
        '三色 Colormap', '三色到 axes', '三色到 panel', '插值颜色数', '编辑控制点/位置', ...
        '图元操作', '删除选中元素', '单点高亮', '比例尺', '磁吸', ...
        '线条样式', '线形', '线宽', '应用到选中图元', ...
        '图例与文本', '添加图例', '添加文本', ...
        '画布缩放', '编辑缩放', '重置缩放 100%', ...
        '输出', 'DPI', '弹出预览窗口', '导出图像', '导出数据 MAT', ...
        '工程文件', '保存工程', '打开工程', ...
        '预览会单独弹出窗口，并与导出图像使用同一个渲染器和同一套 panel/文字位置。', ...
        '高级页是新增功能入口：三色 colormap、图例、指定位置文本、线形线宽和局部放大编辑都在这里。', ...
        '属性', '值', '组图项目', '开', '关', ...
        'Title', 'XLabel', 'YLabel', 'ZLabel', 'Axes', ...
        '低饱和科研论文风格', '高区分度论文风格' ...
    };
    values = { ...
        'Group Figure Composer', 'Workflow', 'Canvas', 'Objects and Properties', ...
        '1 Layout', '2 Import', '3 Refine', '4 Preview / Export', 'Advanced', ...
        'Canvas Size', 'Rows', 'Columns', 'Canvas width (px)', 'Canvas height (px)', ...
        'Panel gap', 'Page margin', 'Create layout', 'Merge Panels', ...
        'Start row', 'Start column', 'Row span', 'Column span', 'Merge', 'Unmerge', ...
        'Asset Import', 'Import to Selected Panel', 'Unified Font', 'Font', 'Font size', ...
        'Apply Frame / Font', 'Auto-align Plot Frames', ...
        'Supports FIG / SVG / PNG / JPG / TIF / BMP. The + button inside an empty panel can also import directly.', ...
        'Panel Label', 'Label', 'Format', 'Apply Label', ...
        'Palette', 'Built-in', 'Import Palette', 'Apply to Selected', 'All Lines', ...
        'Map Colormap', 'Colormap', 'Reverse', 'Apply to Current Axes', 'Apply to Current Panel', ...
        'Custom Colormap', 'Custom to Axes', 'Custom to Panel', 'Interpolated colors', 'Edit Stops / Positions', ...
        'Object Actions', 'Delete Selected Object', 'Highlight Point', 'Scale Bar', 'Snap', ...
        'Line Style', 'Line style', 'Line width', 'Apply to Selected Object', ...
        'Legend and Text', 'Add Legend', 'Add Text', ...
        'Canvas Zoom', 'Edit zoom', 'Reset Zoom 100%', ...
        'Output', 'DPI', 'Open Preview Window', 'Export Figure', 'Export Data MAT', ...
        'Project File', 'Save Project', 'Open Project', ...
        'Preview opens in a separate window and uses the same renderer and panel/text positions as exported figures.', ...
        'Advanced tools: custom colormaps, legends, positioned text, line style/width, and local zoom editing.', ...
        'Property', 'Value', 'Project', 'On', 'Off', ...
        'Title', 'XLabel', 'YLabel', 'ZLabel', 'Axes', ...
        'Muted publication palette', 'High-contrast publication palette' ...
    };
    map = containers.Map(keys, values);
end
dict = map;
end
