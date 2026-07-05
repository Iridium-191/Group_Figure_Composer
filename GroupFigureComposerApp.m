classdef GroupFigureComposerApp < handle
    %GROUPFIGURECOMPOSERAPP Interactive MATLAB tool for composite figures.

    properties
        UIFigure matlab.ui.Figure
        MainGrid matlab.ui.container.GridLayout
        LeftPanel matlab.ui.container.Panel
        CanvasViewport matlab.ui.container.Panel
        CanvasPanel matlab.ui.container.Panel
        RightPanel matlab.ui.container.Panel
        Tree matlab.ui.container.Tree
        PropertyTable matlab.ui.control.Table
        StatusLabel matlab.ui.control.Label
        PreviewImage matlab.ui.control.Image
        PreviewLabel matlab.ui.control.Label
        SnapVLine matlab.ui.control.Label
        SnapHLine matlab.ui.control.Label
        SnapGuideText matlab.ui.control.Label
        ObjectContextMenu matlab.ui.container.ContextMenu

        RowsSpinner matlab.ui.control.Spinner
        ColsSpinner matlab.ui.control.Spinner
        CanvasWidthField matlab.ui.control.NumericEditField
        CanvasHeightField matlab.ui.control.NumericEditField
        DPISpinner matlab.ui.control.Spinner
        MergeRowSpinner matlab.ui.control.Spinner
        MergeColSpinner matlab.ui.control.Spinner
        MergeRowSpanSpinner matlab.ui.control.Spinner
        MergeColSpanSpinner matlab.ui.control.Spinner
        GapField matlab.ui.control.NumericEditField
        MarginField matlab.ui.control.NumericEditField
        FontDropDown matlab.ui.control.DropDown
        FontSizeSpinner matlab.ui.control.Spinner
        LabelField matlab.ui.control.EditField
        LabelFormatDropDown matlab.ui.control.DropDown
        SnapSwitch matlab.ui.control.Switch
        PaletteDropDown matlab.ui.control.DropDown
        PaletteSwatchPanel matlab.ui.container.Panel
        MapDropDown matlab.ui.control.DropDown
        MapReverseCheckBox matlab.ui.control.CheckBox
        CLimField matlab.ui.control.EditField
        CustomMapPanel matlab.ui.container.Panel
        CustomMapCountSpinner matlab.ui.control.Spinner
        LineStyleDropDown matlab.ui.control.DropDown
        LineWidthSpinner matlab.ui.control.Spinner
        CanvasZoomSpinner matlab.ui.control.Spinner
        PaletteButtons = []
        CustomMapButtons = []

        Rows double = 2
        Cols double = 2
        CanvasWidthPx double = 900
        CanvasHeightPx double = 820
        CanvasZoom double = 1
        LeftWidthPx double = 305
        RightWidthPx double = 340
        StyleFontName char = 'Arial'
        StyleFontSize double = 9
        LayoutGap double = 0.025
        LayoutMargin double = 0.045
        Panels struct = gfc.createPanels(2, 2)
        PanelPositions double = []
        AxesPositions double = []
        LabelPositions double = []
        PanelUI struct = struct('PanelId', {}, 'Container', {}, 'Axes', {}, 'Button', {}, 'Label', {})
        AssetInfos struct = struct('sourcePath', {}, 'assetType', {}, 'importReport', {})
        SelectedPanelId double = 1
        SelectedHandle = []
        HighlightedHandle = []
        Palette double = []
        CustomMapColors double = [0.10 0.20 0.55; 0.95 0.95 0.95; 0.75 0.10 0.08]
        CustomMapPositions double = [0; 0.5; 1]
        CustomMapCount double = 256
        InkscapePath char = ''
        LastPreviewFile char = ''
        DragMode char = ''
        DragPanelIndex double = []
        DragStartPoint double = []
        DragStartPosition double = []
        DragStartAxesPosition double = []
        DragStartLabelPosition double = []
        DragEdge char = ''
        DragHandle = []
        DragStartAxesPoint double = []
        DragStartGraphicPosition double = []
        DragStartXData double = []
        DragStartYData double = []
    end

    methods
        function app = GroupFigureComposerApp()
            app.InkscapePath = gfc.checkInkscape();
            app.resetLayoutPositions();
            app.AssetInfos = app.blankAssetInfos(numel(app.Panels));
            app.createComponents();
            app.rebuildCanvas();
            app.refreshTree();
            if isempty(app.InkscapePath)
                app.setStatus('已启动。未检测到 Inkscape；复杂 SVG 会给出解析报告。');
            else
                app.setStatus(['已启动。Inkscape: ' app.InkscapePath]);
            end
        end

        function delete(app)
            if ~isempty(app.LastPreviewFile) && isfile(app.LastPreviewFile)
                try
                    delete(app.LastPreviewFile);
                catch
                end
            end
            if ~isempty(app.UIFigure) && isvalid(app.UIFigure)
                delete(app.UIFigure);
            end
        end
    end

    methods (Access = private)
        function createComponents(app)
            app.UIFigure = uifigure('Name', '组图工具 Group Figure Composer', ...
                'Position', app.fixedWindowPosition(), 'Color', [0.96 0.97 0.98], ...
                'Resize', 'off');
            app.UIFigure.WindowButtonDownFcn = @(~, ~) app.windowMouseDown();
            app.UIFigure.WindowButtonMotionFcn = @(~, ~) app.windowMouseMove();
            app.UIFigure.WindowButtonUpFcn = @(~, ~) app.windowMouseUp();
            app.UIFigure.KeyPressFcn = @(~, event) app.keyPressed(event);
            app.ObjectContextMenu = uicontextmenu(app.UIFigure);
            uimenu(app.ObjectContextMenu, 'Text', '删除选中元素', ...
                'MenuSelectedFcn', @(~, ~) app.deleteSelectedGraphic());

            app.MainGrid = uigridlayout(app.UIFigure, [1 3]);
            app.MainGrid.ColumnWidth = {app.LeftWidthPx, app.CanvasWidthPx, app.RightWidthPx};
            app.MainGrid.RowHeight = {app.CanvasHeightPx};
            app.MainGrid.Padding = [10 10 10 10];
            app.MainGrid.ColumnSpacing = 10;

            app.LeftPanel = uipanel(app.MainGrid, 'Title', '流程', 'FontWeight', 'bold');
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;
            app.CanvasPanel = uipanel(app.MainGrid, 'Title', '画布', 'FontWeight', 'bold', ...
                'BackgroundColor', [1 1 1], 'AutoResizeChildren', 'off');
            app.CanvasPanel.SizeChangedFcn = @(~, ~) app.positionPanelUI();
            try
                app.CanvasPanel.Scrollable = 'on';
            catch
            end
            app.CanvasPanel.Layout.Row = 1;
            app.CanvasPanel.Layout.Column = 2;
            app.RightPanel = uipanel(app.MainGrid, 'Title', '对象与属性', 'FontWeight', 'bold');
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 3;

            app.createLeftControls();
            app.createRightControls();
        end

        function createLeftControls(app)
            outer = uigridlayout(app.LeftPanel, [2 1]);
            outer.RowHeight = {'1x', 72};
            outer.Padding = [8 8 8 8];
            outer.RowSpacing = 8;

            tabs = uitabgroup(outer);
            tabs.Layout.Row = 1;
            layoutTab = uitab(tabs, 'Title', '1 布局');
            importTab = uitab(tabs, 'Title', '2 导入');
            refineTab = uitab(tabs, 'Title', '3 精修');
            previewTab = uitab(tabs, 'Title', '4 预览导出');

            app.buildLayoutTab(layoutTab);
            app.buildImportTab(importTab);
            app.buildRefineTab(refineTab);
            advancedTab = uitab(tabs, 'Title', '高级');
            app.buildAdvancedTab(advancedTab);
            app.buildPreviewTab(previewTab);

            app.StatusLabel = uilabel(outer, 'Text', '', 'WordWrap', 'on', ...
                'FontColor', [0.18 0.22 0.28], 'BackgroundColor', [0.92 0.95 0.98]);
            app.StatusLabel.Layout.Row = 2;
        end

        function buildLayoutTab(app, parent)
            grid = app.makeTabGrid(parent, 22);
            app.addSection(grid, 1, '画布尺寸');
            app.addLabel(grid, 2, '行数');
            app.RowsSpinner = uispinner(grid, 'Limits', [1 20], 'Value', app.Rows, 'Step', 1);
            app.place(app.RowsSpinner, 2, 2);
            app.addLabel(grid, 3, '列数');
            app.ColsSpinner = uispinner(grid, 'Limits', [1 20], 'Value', app.Cols, 'Step', 1);
            app.place(app.ColsSpinner, 3, 2);
            app.addLabel(grid, 4, '画布宽 px');
            app.CanvasWidthField = uieditfield(grid, 'numeric', 'Value', app.CanvasWidthPx, 'Limits', [480 2400]);
            app.place(app.CanvasWidthField, 4, 2);
            app.addLabel(grid, 5, '画布高 px');
            app.CanvasHeightField = uieditfield(grid, 'numeric', 'Value', app.CanvasHeightPx, 'Limits', [360 1800]);
            app.place(app.CanvasHeightField, 5, 2);
            app.addLabel(grid, 6, 'Panel 间距');
            app.GapField = uieditfield(grid, 'numeric', 'Value', app.LayoutGap, 'Limits', [0 0.25]);
            app.GapField.ValueChangedFcn = @(~, ~) app.applyLayoutSpacing();
            app.place(app.GapField, 6, 2);
            app.addLabel(grid, 7, '页面边距');
            app.MarginField = uieditfield(grid, 'numeric', 'Value', app.LayoutMargin, 'Limits', [0 0.25]);
            app.MarginField.ValueChangedFcn = @(~, ~) app.applyLayoutSpacing();
            app.place(app.MarginField, 7, 2);
            b = app.primaryButton(grid, '新建布局', @(~, ~) app.newLayout());
            app.place(b, 8, [1 2]);

            app.addSection(grid, 10, '合并区域');
            app.addLabel(grid, 11, '起始行');
            app.MergeRowSpinner = uispinner(grid, 'Limits', [1 20], 'Value', 1, 'Step', 1);
            app.place(app.MergeRowSpinner, 11, 2);
            app.addLabel(grid, 12, '起始列');
            app.MergeColSpinner = uispinner(grid, 'Limits', [1 20], 'Value', 1, 'Step', 1);
            app.place(app.MergeColSpinner, 12, 2);
            app.addLabel(grid, 13, '跨行');
            app.MergeRowSpanSpinner = uispinner(grid, 'Limits', [1 20], 'Value', 1, 'Step', 1);
            app.place(app.MergeRowSpanSpinner, 13, 2);
            app.addLabel(grid, 14, '跨列');
            app.MergeColSpanSpinner = uispinner(grid, 'Limits', [1 20], 'Value', 1, 'Step', 1);
            app.place(app.MergeColSpanSpinner, 14, 2);
            bm = uibutton(grid, 'Text', '合并', 'ButtonPushedFcn', @(~, ~) app.mergeRange());
            app.place(bm, 15, 1);
            bu = uibutton(grid, 'Text', '取消合并', 'ButtonPushedFcn', @(~, ~) app.unmergeSelected());
            app.place(bu, 15, 2);
        end

        function buildImportTab(app, parent)
            grid = app.makeTabGrid(parent, 12);
            app.addSection(grid, 1, '素材导入');
            b = app.primaryButton(grid, '导入到选中 panel', @(~, ~) app.importSelected());
            app.place(b, 2, [1 2]);
            app.addSection(grid, 4, '统一字体');
            app.addLabel(grid, 5, '字体');
            app.FontDropDown = uidropdown(grid, 'Items', app.fontItems(), 'Value', app.StyleFontName, ...
                'ValueChangedFcn', @(~, ~) app.styleAll());
            app.place(app.FontDropDown, 5, 2);
            app.addLabel(grid, 6, '字号');
            app.FontSizeSpinner = uispinner(grid, 'Limits', [4 72], 'Value', app.StyleFontSize, ...
                'Step', 1, 'ValueChangedFcn', @(~, ~) app.styleAll());
            app.place(app.FontSizeSpinner, 6, 2);
            bs = uibutton(grid, 'Text', '统一框线/字体', 'ButtonPushedFcn', @(~, ~) app.styleAll());
            app.place(bs, 7, [1 2]);
            ba = uibutton(grid, 'Text', '自动对齐绘图区框线', ...
                'ButtonPushedFcn', @(~, ~) app.alignAxesFrames());
            app.place(ba, 8, [1 2]);
            info = uilabel(grid, 'Text', '支持 FIG / SVG / PNG / JPG / TIF / BMP。空 panel 中的 + 也可以直接导入。', ...
                'WordWrap', 'on', 'FontColor', [0.30 0.34 0.40]);
            info.Layout.Row = [10 12];
            info.Layout.Column = [1 2];
        end

        function buildRefineTab(app, parent)
            try
                parent.Scrollable = 'on';
            catch
            end
            grid = app.makeTabGrid(parent, 36);
            app.addSection(grid, 1, 'Panel 编号');
            app.addLabel(grid, 2, '编号');
            app.LabelField = uieditfield(grid, 'text', 'Value', 'a');
            app.place(app.LabelField, 2, 2);
            app.addLabel(grid, 3, '格式');
            app.LabelFormatDropDown = uidropdown(grid, 'Items', {'%s','(%s)','%s.','Fig. %s','Panel %s'}, 'Value', '%s');
            app.place(app.LabelFormatDropDown, 3, 2);
            bl = uibutton(grid, 'Text', '应用编号', 'ButtonPushedFcn', @(~, ~) app.applyPanelLabel());
            app.place(bl, 4, [1 2]);

            app.addSection(grid, 6, '色卡');
            app.addLabel(grid, 7, '内置');
            app.PaletteDropDown = uidropdown(grid, 'Items', app.paletteItems(), ...
                'Value', 'Okabe-Ito', 'ValueChangedFcn', @(~, ~) app.chooseBuiltinPalette());
            app.place(app.PaletteDropDown, 7, 2);
            app.PaletteSwatchPanel = uipanel(grid, 'Title', '');
            app.PaletteSwatchPanel.Layout.Row = 8;
            app.PaletteSwatchPanel.Layout.Column = [1 2];
            app.createPaletteSwatches();
            bp = uibutton(grid, 'Text', '导入色卡', 'ButtonPushedFcn', @(~, ~) app.importPalette());
            app.place(bp, 9, 1);
            bs = uibutton(grid, 'Text', '应用到选中', 'ButtonPushedFcn', @(~, ~) app.applyPaletteToSelected());
            app.place(bs, 9, 2);
            ba = uibutton(grid, 'Text', '所有谱线', 'ButtonPushedFcn', @(~, ~) app.applyPalette());
            app.place(ba, 10, [1 2]);

            app.addSection(grid, 12, 'Map Colormap');
            app.addLabel(grid, 13, 'Colormap');
            app.MapDropDown = uidropdown(grid, 'Items', app.colormapItems(), ...
                'Value', 'Viridis', 'ValueChangedFcn', @(~, ~) app.previewSelectedColormap());
            app.place(app.MapDropDown, 13, 2);
            app.MapReverseCheckBox = uicheckbox(grid, 'Text', '反转', ...
                'ValueChangedFcn', @(~, ~) app.previewSelectedColormap());
            app.place(app.MapReverseCheckBox, 14, 1);
            app.CLimField = uieditfield(grid, 'text', 'Value', '');
            app.place(app.CLimField, 14, 2);
            bcax = uibutton(grid, 'Text', '应用到当前 axes', ...
                'ButtonPushedFcn', @(~, ~) app.applyMapColormap(false));
            app.place(bcax, 15, 1);
            bcp = uibutton(grid, 'Text', '应用到当前 panel', ...
                'ButtonPushedFcn', @(~, ~) app.applyMapColormap(true));
            app.place(bcp, 15, 2);

            app.CustomMapPanel = uipanel(grid, 'Title', '');
            app.CustomMapPanel.Layout.Row = 29;
            app.CustomMapPanel.Layout.Column = [1 2];
            app.createCustomMapControls();
            bcustomAx = uibutton(grid, 'Text', '三色到 axes', ...
                'ButtonPushedFcn', @(~, ~) app.applyCustomColormap(false));
            app.place(bcustomAx, 30, 1);
            bcustomPanel = uibutton(grid, 'Text', '三色到 panel', ...
                'ButtonPushedFcn', @(~, ~) app.applyCustomColormap(true));
            app.place(bcustomPanel, 30, 2);

            app.addSection(grid, 17, '图元操作');
            bd = uibutton(grid, 'Text', '删除选中元素', 'ButtonPushedFcn', @(~, ~) app.deleteSelectedGraphic());
            bd.FontWeight = 'bold';
            app.place(bd, 18, [1 2]);
            bh = uibutton(grid, 'Text', '单点高亮', 'ButtonPushedFcn', @(~, ~) app.addHighlight());
            app.place(bh, 19, 1);
            bscale = uibutton(grid, 'Text', '比例尺', 'ButtonPushedFcn', @(~, ~) app.addScaleBar());
            app.place(bscale, 19, 2);
            app.addLabel(grid, 21, '磁吸');
            app.SnapSwitch = uiswitch(grid, 'slider', 'Items', {'关','开'}, 'Value', '开');
            app.place(app.SnapSwitch, 21, 2);

            app.addSection(grid, 23, '线条样式');
            app.addLabel(grid, 24, '线形');
            app.LineStyleDropDown = uidropdown(grid, 'Items', app.lineStyleItems(), ...
                'Value', '-', 'ValueChangedFcn', @(~, ~) app.applyLineStyleToSelected());
            app.place(app.LineStyleDropDown, 24, 2);
            app.addLabel(grid, 25, '线宽');
            app.LineWidthSpinner = uispinner(grid, 'Limits', [0.1 30], ...
                'Value', 1, 'Step', 0.25, 'ValueChangedFcn', @(~, ~) app.applyLineStyleToSelected());
            app.place(app.LineWidthSpinner, 25, 2);
            bline = uibutton(grid, 'Text', '应用到选中图元', ...
                'ButtonPushedFcn', @(~, ~) app.applyLineStyleToSelected());
            app.place(bline, 26, [1 2]);

            blegend = uibutton(grid, 'Text', '添加图例', 'ButtonPushedFcn', @(~, ~) app.addLegend());
            app.place(blegend, 27, 1);
            btext = uibutton(grid, 'Text', '添加文本', 'ButtonPushedFcn', @(~, ~) app.addTextAtPosition());
            app.place(btext, 27, 2);

            app.addSection(grid, 32, '画布缩放');
            app.addLabel(grid, 33, '编辑缩放');
            app.CanvasZoomSpinner = uispinner(grid, 'Limits', [0.5 3], 'Value', app.CanvasZoom, ...
                'Step', 0.1, 'ValueChangedFcn', @(~, ~) app.applyCanvasZoom());
            app.place(app.CanvasZoomSpinner, 33, 2);
            bzoom = uibutton(grid, 'Text', '重置缩放 100%', 'ButtonPushedFcn', @(~, ~) app.resetCanvasZoom());
            app.place(bzoom, 34, [1 2]);

            app.Palette = gfc.builtinPalettes('Okabe-Ito', 8);
            app.updatePaletteSwatches();
        end

        function buildAdvancedTab(app, parent)
            grid = app.makeTabGrid(parent, 22);

            app.addSection(grid, 1, '三色 Colormap');
            app.CustomMapPanel = uipanel(grid, 'Title', '');
            app.CustomMapPanel.Layout.Row = 2;
            app.CustomMapPanel.Layout.Column = [1 2];
            app.createCustomMapControls();
            bcustomAx = uibutton(grid, 'Text', '三色到 axes', ...
                'ButtonPushedFcn', @(~, ~) app.applyCustomColormap(false));
            app.place(bcustomAx, 3, 1);
            bcustomPanel = uibutton(grid, 'Text', '三色到 panel', ...
                'ButtonPushedFcn', @(~, ~) app.applyCustomColormap(true));
            app.place(bcustomPanel, 3, 2);
            bcustomEdit = uibutton(grid, 'Text', '编辑控制点/位置', ...
                'ButtonPushedFcn', @(~, ~) app.editCustomMapStops());
            app.place(bcustomEdit, 4, [1 2]);
            app.addLabel(grid, 5, '插值颜色数');
            app.CustomMapCountSpinner = uispinner(grid, 'Limits', [2 4096], ...
                'RoundFractionalValues', 'on', 'Value', app.CustomMapCount, ...
                'Step', 1, 'ValueChangedFcn', @(~, ~) app.updateCustomMapCount());
            app.place(app.CustomMapCountSpinner, 5, 2);

            app.addSection(grid, 6, '图例与文本');
            blegend = uibutton(grid, 'Text', '添加图例', 'ButtonPushedFcn', @(~, ~) app.addLegend());
            app.place(blegend, 7, 1);
            btext = uibutton(grid, 'Text', '添加文本', 'ButtonPushedFcn', @(~, ~) app.addTextAtPosition());
            app.place(btext, 7, 2);

            app.addSection(grid, 9, '线条样式');
            app.addLabel(grid, 10, '线形');
            app.LineStyleDropDown = uidropdown(grid, 'Items', app.lineStyleItems(), ...
                'Value', '-', 'ValueChangedFcn', @(~, ~) app.applyLineStyleToSelected());
            app.place(app.LineStyleDropDown, 10, 2);
            app.addLabel(grid, 11, '线宽');
            app.LineWidthSpinner = uispinner(grid, 'Limits', [0.1 30], ...
                'Value', 1, 'Step', 0.25, 'ValueChangedFcn', @(~, ~) app.applyLineStyleToSelected());
            app.place(app.LineWidthSpinner, 11, 2);
            bline = uibutton(grid, 'Text', '应用到选中图元', ...
                'ButtonPushedFcn', @(~, ~) app.applyLineStyleToSelected());
            app.place(bline, 12, [1 2]);

            app.addSection(grid, 14, '画布缩放');
            app.addLabel(grid, 15, '编辑缩放');
            app.CanvasZoomSpinner = uispinner(grid, 'Limits', [0.5 3], 'Value', app.CanvasZoom, ...
                'Step', 0.1, 'ValueChangedFcn', @(~, ~) app.applyCanvasZoom());
            app.place(app.CanvasZoomSpinner, 15, 2);
            bzoom = uibutton(grid, 'Text', '重置缩放 100%', 'ButtonPushedFcn', @(~, ~) app.resetCanvasZoom());
            app.place(bzoom, 16, [1 2]);

            info = uilabel(grid, 'Text', '高级页是新增功能入口：三色 colormap、图例、指定位置文本、线形线宽和局部放大编辑都在这里。', ...
                'WordWrap', 'on', 'FontColor', [0.30 0.34 0.40]);
            info.Layout.Row = [18 22];
            info.Layout.Column = [1 2];
        end

        function buildPreviewTab(app, parent)
            grid = app.makeTabGrid(parent, 22);
            app.addSection(grid, 1, '输出');
            app.addLabel(grid, 2, 'DPI');
            app.DPISpinner = uispinner(grid, 'Limits', [72 1200], 'Value', 300, 'Step', 50);
            app.place(app.DPISpinner, 2, 2);
            bprev = app.primaryButton(grid, '弹出预览窗口', @(~, ~) app.previewFigure());
            app.place(bprev, 3, [1 2]);
            bex = uibutton(grid, 'Text', '导出图像', 'ButtonPushedFcn', @(~, ~) app.exportFigure());
            app.place(bex, 4, [1 2]);
            bdata = uibutton(grid, 'Text', '导出数据 MAT', 'ButtonPushedFcn', @(~, ~) app.exportDataMat());
            app.place(bdata, 5, [1 2]);

            app.addSection(grid, 7, '工程文件');
            bsave = uibutton(grid, 'Text', '保存工程', 'ButtonPushedFcn', @(~, ~) app.exportProject());
            app.place(bsave, 8, [1 2]);
            bopen = uibutton(grid, 'Text', '打开工程', 'ButtonPushedFcn', @(~, ~) app.importProject());
            app.place(bopen, 9, [1 2]);

            app.PreviewLabel = uilabel(grid, 'Text', '预览会单独弹出窗口，并与导出图像使用同一个渲染器和同一套 panel/文字位置。', ...
                'WordWrap', 'on', 'FontColor', [0.30 0.34 0.40]);
            app.PreviewLabel.Layout.Row = [12 22];
            app.PreviewLabel.Layout.Column = [1 2];
        end

        function grid = makeTabGrid(~, parent, rows)
            grid = uigridlayout(parent, [rows 2]);
            grid.RowHeight = repmat({28}, 1, rows);
            grid.ColumnWidth = {105, '1x'};
            grid.Padding = [10 12 10 10];
            grid.RowSpacing = 7;
            grid.ColumnSpacing = 8;
        end

        function addSection(~, grid, row, textValue)
            label = uilabel(grid, 'Text', textValue, 'FontWeight', 'bold', ...
                'FontSize', 13, 'FontColor', [0.10 0.18 0.28]);
            label.Layout.Row = row;
            label.Layout.Column = [1 2];
        end

        function addLabel(~, grid, row, textValue)
            label = uilabel(grid, 'Text', textValue, 'FontColor', [0.24 0.28 0.34]);
            label.Layout.Row = row;
            label.Layout.Column = 1;
        end

        function button = primaryButton(~, parent, textValue, callback)
            button = uibutton(parent, 'Text', textValue, 'ButtonPushedFcn', callback);
            button.FontWeight = 'bold';
            button.BackgroundColor = [0.12 0.36 0.62];
            button.FontColor = [1 1 1];
        end

        function place(~, component, row, col)
            component.Layout.Row = row;
            component.Layout.Column = col;
        end

        function createRightControls(app)
            grid = uigridlayout(app.RightPanel, [2 1]);
            grid.RowHeight = {'1x', 240};
            grid.Padding = [8 8 8 8];
            grid.RowSpacing = 8;

            app.Tree = uitree(grid, 'SelectionChangedFcn', @(~, event) app.treeSelectionChanged(event));
            app.Tree.Layout.Row = 1;

            app.PropertyTable = uitable(grid, ...
                'ColumnName', {'属性', '值'}, ...
                'ColumnEditable', [false true], ...
                'CellEditCallback', @(~, event) app.propertyEdited(event));
            app.PropertyTable.Layout.Row = 2;
        end

        function resetLayoutPositions(app)
            app.PanelPositions = gfc.panelPositions(app.Panels, app.Rows, app.Cols, ...
                app.LayoutGap, app.LayoutMargin);
            app.AxesPositions = app.defaultAxesPositions();
            app.LabelPositions = repmat([0.015 0.915 0.18 0.065], numel(app.Panels), 1);
        end

        function positions = defaultAxesPositions(app)
            positions = zeros(numel(app.Panels), 4);
            for k = 1:numel(app.Panels)
                pad = min(max(app.Panels(k).innerPadding, 0), 0.35);
                positions(k, :) = [pad, pad, 1 - 2*pad, 1 - 2*pad];
            end
        end

        function pos = fixedWindowPosition(app)
            padding = 20;
            spacing = 20;
            width = app.LeftWidthPx + app.CanvasWidthPx + app.RightWidthPx + padding + spacing;
            height = app.CanvasHeightPx + padding;
            pos = [80 80 width height];
        end

        function applyFixedWindowSize(app)
            if ~isempty(app.MainGrid) && isvalid(app.MainGrid)
                app.MainGrid.ColumnWidth = {app.LeftWidthPx, app.CanvasWidthPx, app.RightWidthPx};
                app.MainGrid.RowHeight = {app.CanvasHeightPx};
            end
            if ~isempty(app.UIFigure) && isvalid(app.UIFigure)
                app.UIFigure.Resize = 'off';
                old = app.UIFigure.Position;
                pos = app.fixedWindowPosition();
                app.UIFigure.Position = [old(1) old(2) pos(3) pos(4)];
            end
            app.positionPanelUI();
        end

        function displaySize = displayCanvasSize(app)
            scale = max(0.5, min(3, app.CanvasZoom));
            displaySize = max([120 90], round([app.CanvasWidthPx app.CanvasHeightPx] * scale));
        end

        function rect = editorCanvasRect(app)
            viewportRect = getpixelposition(app.CanvasPanel, true);
            displaySize = app.displayCanvasSize();
            rect = [viewportRect(1), viewportRect(2), displaySize(1), displaySize(2)];
        end

        function ensureLayoutState(app)
            if isempty(app.PanelPositions) || size(app.PanelPositions, 1) ~= numel(app.Panels)
                app.PanelPositions = gfc.panelPositions(app.Panels, app.Rows, app.Cols, ...
                    app.LayoutGap, app.LayoutMargin);
            end
            if isempty(app.AxesPositions) || size(app.AxesPositions, 1) ~= numel(app.Panels)
                app.AxesPositions = app.defaultAxesPositions();
            end
            if isempty(app.LabelPositions) || size(app.LabelPositions, 1) ~= numel(app.Panels)
                app.LabelPositions = repmat([0.015 0.915 0.18 0.065], numel(app.Panels), 1);
            end
        end

        function applyLayoutSpacing(app)
            app.LayoutGap = app.GapField.Value;
            app.LayoutMargin = app.MarginField.Value;
            app.resetLayoutPositions();
            app.positionPanelUI();
            app.setStatus('已按新的 panel 间距和页面边距重新排布。');
        end

        function applyCanvasZoom(app)
            if ~isempty(app.CanvasZoomSpinner) && isvalid(app.CanvasZoomSpinner)
                app.CanvasZoom = app.CanvasZoomSpinner.Value;
            end
            app.applyFixedWindowSize();
            app.setStatus(sprintf('画布编辑缩放 %.0f%%，导出像素尺寸仍为 %d x %d。', ...
                100 * app.CanvasZoom, app.CanvasWidthPx, app.CanvasHeightPx));
        end

        function resetCanvasZoom(app)
            app.CanvasZoom = 1;
            if ~isempty(app.CanvasZoomSpinner) && isvalid(app.CanvasZoomSpinner)
                app.CanvasZoomSpinner.Value = 1;
            end
            app.applyFixedWindowSize();
            app.setStatus('已重置画布编辑缩放为 100%。');
        end

        function items = fontItems(~)
            fallback = {'Arial','Helvetica','Times New Roman','Calibri', ...
                'Microsoft YaHei','SimSun','Cambria','Courier New'};
            try
                fonts = cellstr(listfonts);
                items = [fallback, setdiff(fonts(:).', fallback, 'stable')];
                if isempty(items)
                    items = fallback;
                end
            catch
                items = fallback;
            end
        end

        function items = paletteItems(~)
            items = {'Okabe-Ito','Nature Muted','Science Bright','Tableau 10', ...
                'ColorBrewer Set2','ColorBrewer Dark2','Gray','Viridis','Cividis', ...
                'Magma','Inferno','Plasma','Turbo','Parula','Jet','CoolWarm'};
        end

        function items = colormapItems(~)
            items = {'Viridis','Cividis','Magma','Inferno','Plasma','Turbo', ...
                'Parula','Jet','Gray','CoolWarm'};
        end

        function items = lineStyleItems(~)
            items = {'-','--',':','-.','none'};
        end

        function createPaletteSwatches(app)
            delete(app.PaletteSwatchPanel.Children);
            grid = uigridlayout(app.PaletteSwatchPanel, [1 10]);
            grid.Padding = [4 3 4 3];
            grid.RowHeight = {'1x'};
            grid.ColumnWidth = repmat({22}, 1, 10);
            grid.ColumnSpacing = 4;
            app.PaletteButtons = cell(1, 10);
            for k = 1:10
                btn = uibutton(grid, 'Text', '', ...
                    'ButtonPushedFcn', @(~, ~) app.applySwatchColor(k));
                btn.Layout.Row = 1;
                btn.Layout.Column = k;
                app.PaletteButtons{k} = btn;
            end
        end

        function createCustomMapControls(app)
            delete(app.CustomMapPanel.Children);
            n = size(app.CustomMapColors, 1);
            if numel(app.CustomMapPositions) ~= n
                app.CustomMapPositions = linspace(0, 1, n).';
            else
                app.CustomMapPositions = app.CustomMapPositions(:);
            end
            grid = uigridlayout(app.CustomMapPanel, [1 n]);
            grid.Padding = [4 3 4 3];
            grid.RowHeight = {'1x'};
            grid.ColumnWidth = repmat({'1x'}, 1, n);
            grid.ColumnSpacing = 5;
            app.CustomMapButtons = cell(1, n);
            for k = 1:n
                btn = uibutton(grid, 'Text', sprintf('C%d', k), ...
                    'ButtonPushedFcn', @(~, ~) app.chooseCustomMapColor(k));
                btn.Layout.Row = 1;
                btn.Layout.Column = k;
                app.CustomMapButtons{k} = btn;
            end
            app.updateCustomMapButtons();
        end

        function updateCustomMapButtons(app)
            for k = 1:numel(app.CustomMapButtons)
                btn = app.CustomMapButtons{k};
                if isempty(btn) || ~isvalid(btn)
                    continue
                end
                btn.BackgroundColor = app.CustomMapColors(k, :);
                btn.Tooltip = sprintf('三色 colormap 控制点 %d: RGB [%0.3f %0.3f %0.3f]', ...
                    k, app.CustomMapColors(k, :));
                btn.Tooltip = sprintf('Colormap stop %d, position %g, RGB [%0.3f %0.3f %0.3f]', ...
                    k, app.CustomMapPositions(k), app.CustomMapColors(k, :));
            end
        end

        function updateCustomMapCount(app)
            if isempty(app.CustomMapCountSpinner) || ~isvalid(app.CustomMapCountSpinner)
                return
            end
            app.CustomMapCount = max(2, round(app.CustomMapCountSpinner.Value));
            app.CustomMapCountSpinner.Value = app.CustomMapCount;
            app.setStatus(sprintf('Colormap 插值颜色数已设为 %d。', app.CustomMapCount));
        end

        function updatePaletteSwatches(app)
            if isempty(app.PaletteButtons)
                return
            end
            n = size(app.Palette, 1);
            for k = 1:numel(app.PaletteButtons)
                btn = app.PaletteButtons{k};
                if isempty(btn) || ~isvalid(btn)
                    continue
                end
                if k <= n
                    btn.BackgroundColor = app.Palette(k, :);
                    btn.Enable = 'on';
                    btn.Tooltip = sprintf('RGB [%0.3f %0.3f %0.3f]', app.Palette(k, :));
                else
                    btn.BackgroundColor = [0.94 0.94 0.94];
                    btn.Enable = 'off';
                    btn.Tooltip = '';
                end
            end
        end

        function windowMouseDown(app)
            app.DragMode = '';
            app.DragHandle = [];
            point = app.UIFigure.CurrentPoint;
            [labelIdx, onLabel] = app.hitTestLabel(point);
            if onLabel
                app.startLabelDrag(labelIdx, point);
                return
            end
            [axesIdx, axesEdgeName] = app.hitTestAxesEdge(point);
            if ~isempty(axesIdx)
                app.startAxesDrag(axesIdx, axesEdgeName, point);
                return
            end
            [panelIdx, edgeName] = app.hitTestPanelEdge(point);
            if ~isempty(panelIdx)
                app.startPanelDrag(panelIdx, edgeName, point);
                return
            end

            h = app.UIFigure.CurrentObject;
            if isempty(h) || ~isgraphics(h)
                return
            end
            if isa(h, 'matlab.ui.container.Tree') || isa(h, 'matlab.ui.control.Table')
                return
            end
            panelIdx = app.containerIndex(h);
            if ~isempty(panelIdx)
                app.startPanelMove(panelIdx, point);
                return
            end
            ax = ancestor(h, 'matlab.ui.control.UIAxes');
            if isempty(ax) && isa(h, 'matlab.ui.control.UIAxes')
                ax = h;
            end
            if isempty(ax) || ~isgraphics(ax)
                return
            end
            idx = app.axesIndex(ax);
            if isempty(idx)
                return
            end
            app.selectPanel(app.PanelUI(idx).PanelId);
            if h == ax || isa(h, 'matlab.ui.control.UIAxes')
                app.startAxesMove(idx, point);
            elseif h ~= ax && ~isa(h, 'matlab.ui.control.UIAxes')
                app.selectGraphic(h);
                if app.isDraggableGraphic(h)
                    app.startGraphicDrag(h);
                end
            end
        end

        function windowMouseMove(app)
            if isempty(app.DragMode)
                point = app.UIFigure.CurrentPoint;
                [~, onLabel] = app.hitTestLabel(point);
                [axesIdx, axesEdgeName] = app.hitTestAxesEdge(point);
                [panelIdx, edgeName] = app.hitTestPanelEdge(point);
                if onLabel
                    app.UIFigure.Pointer = dragPointer(edgeName, onLabel);
                elseif ~isempty(axesIdx)
                    app.UIFigure.Pointer = dragPointer(axesEdgeName, false);
                elseif ~isempty(panelIdx)
                    app.UIFigure.Pointer = dragPointer(edgeName, false);
                else
                    app.UIFigure.Pointer = 'arrow';
                end
                return
            end

            switch app.DragMode
                case 'label'
                    app.dragLabel(app.UIFigure.CurrentPoint);
                case 'panel'
                    app.dragPanel(app.UIFigure.CurrentPoint);
                case 'axes'
                    app.dragAxes(app.UIFigure.CurrentPoint);
                case 'graphic'
                    app.dragGraphic();
            end
        end

        function windowMouseUp(app)
            if ~isempty(app.DragMode)
                app.DragMode = '';
                app.DragPanelIndex = [];
                app.DragEdge = '';
                app.DragHandle = [];
                app.DragStartAxesPosition = [];
                app.UIFigure.Pointer = 'arrow';
                app.hideSnapGuides();
                app.refreshTree();
                app.setStatus('已更新位置。预览和导出会使用当前画布位置。');
            end
        end

        function keyPressed(app, event)
            if any(strcmp(event.Key, {'delete', 'backspace'}))
                app.deleteSelectedGraphic();
            end
        end

        function [idx, hit] = hitTestLabel(app, point)
            idx = [];
            hit = false;
            for k = 1:numel(app.PanelUI)
                if ~isgraphics(app.PanelUI(k).Label)
                    continue
                end
                rect = getpixelposition(app.PanelUI(k).Label, true);
                if pointInRect(point, rect)
                    idx = k;
                    hit = true;
                    return
                end
            end
        end

        function [idx, edgeName] = hitTestPanelEdge(app, point)
            idx = [];
            edgeName = '';
            threshold = 18;
            for k = 1:numel(app.PanelUI)
                if ~isgraphics(app.PanelUI(k).Container)
                    continue
                end
                rect = getpixelposition(app.PanelUI(k).Container, true);
                expanded = rect + [-threshold -threshold 2*threshold 2*threshold];
                [nearLeft, nearRight, nearBottom, nearTop] = edgeFlags(point, rect, threshold);
                if pointInRect(point, expanded) && (nearLeft || nearRight || nearBottom || nearTop)
                    idx = k;
                    parts = {};
                    if nearLeft, parts{end + 1} = 'left'; end %#ok<AGROW>
                    if nearRight, parts{end + 1} = 'right'; end %#ok<AGROW>
                    if nearBottom, parts{end + 1} = 'bottom'; end %#ok<AGROW>
                    if nearTop, parts{end + 1} = 'top'; end %#ok<AGROW>
                    edgeName = strjoin(parts, '-');
                    return
                end
            end
        end

        function [idx, edgeName] = hitTestAxesEdge(app, point)
            idx = [];
            edgeName = '';
            threshold = 12;
            for k = 1:numel(app.PanelUI)
                if ~isgraphics(app.PanelUI(k).Axes)
                    continue
                end
                rect = app.axesFramePixelRect(k);
                expanded = rect + [-threshold -threshold 2*threshold 2*threshold];
                [nearLeft, nearRight, nearBottom, nearTop] = edgeFlags(point, rect, threshold);
                if pointInRect(point, expanded) && (nearLeft || nearRight || nearBottom || nearTop)
                    idx = k;
                    parts = {};
                    if nearLeft, parts{end + 1} = 'left'; end %#ok<AGROW>
                    if nearRight, parts{end + 1} = 'right'; end %#ok<AGROW>
                    if nearBottom, parts{end + 1} = 'bottom'; end %#ok<AGROW>
                    if nearTop, parts{end + 1} = 'top'; end %#ok<AGROW>
                    edgeName = strjoin(parts, '-');
                    return
                end
            end
        end

        function startLabelDrag(app, idx, point)
            app.selectPanel(app.PanelUI(idx).PanelId);
            app.DragMode = 'label';
            app.DragPanelIndex = idx;
            app.DragStartPoint = point;
            app.DragStartLabelPosition = app.LabelPositions(idx, :);
            app.UIFigure.Pointer = 'fleur';
        end

        function startPanelDrag(app, idx, edgeName, point)
            app.selectPanel(app.PanelUI(idx).PanelId);
            app.DragMode = 'panel';
            app.DragPanelIndex = idx;
            app.DragEdge = edgeName;
            app.DragStartPoint = point;
            app.DragStartPosition = app.PanelPositions(idx, :);
            app.UIFigure.Pointer = dragPointer(edgeName, false);
        end

        function startPanelMove(app, idx, point)
            if isempty(idx) || idx > numel(app.PanelUI)
                return
            end
            app.selectPanel(app.PanelUI(idx).PanelId);
            app.DragMode = 'panel';
            app.DragPanelIndex = idx;
            app.DragEdge = 'move';
            app.DragStartPoint = point;
            app.DragStartPosition = app.PanelPositions(idx, :);
            app.UIFigure.Pointer = 'fleur';
        end

        function startAxesDrag(app, idx, edgeName, point)
            app.selectPanel(app.PanelUI(idx).PanelId);
            app.DragMode = 'axes';
            app.DragPanelIndex = idx;
            app.DragEdge = edgeName;
            app.DragStartPoint = point;
            app.DragStartAxesPosition = app.AxesPositions(idx, :);
            app.UIFigure.Pointer = dragPointer(edgeName, false);
        end

        function startAxesMove(app, idx, point)
            if isempty(idx) || idx > numel(app.PanelUI)
                return
            end
            app.selectPanel(app.PanelUI(idx).PanelId);
            app.DragMode = 'axes';
            app.DragPanelIndex = idx;
            app.DragEdge = 'move';
            app.DragStartPoint = point;
            app.DragStartAxesPosition = app.AxesPositions(idx, :);
            app.UIFigure.Pointer = 'fleur';
        end

        function dragLabel(app, point)
            idx = app.DragPanelIndex;
            if isempty(idx) || idx > numel(app.PanelUI)
                return
            end
            rect = getpixelposition(app.PanelUI(idx).Container, true);
            delta = point - app.DragStartPoint;
            pos = app.DragStartLabelPosition;
            pos(1) = pos(1) + delta(1) / max(rect(3), 1);
            pos(2) = pos(2) + delta(2) / max(rect(4), 1);
            pos(1) = min(max(pos(1), 0), max(0, 1 - pos(3)));
            pos(2) = min(max(pos(2), 0), max(0, 1 - pos(4)));
            [pos, guide] = app.snapLabelPosition(idx, pos);
            app.LabelPositions(idx, :) = pos;
            app.positionPanelUI();
            app.showSnapGuide(guide);
        end

        function dragAxes(app, point)
            idx = app.DragPanelIndex;
            if isempty(idx) || idx > numel(app.PanelUI)
                return
            end
            panelRect = getpixelposition(app.PanelUI(idx).Container, true);
            delta = point - app.DragStartPoint;
            dx = delta(1) / max(panelRect(3), 1);
            dy = delta(2) / max(panelRect(4), 1);
            pos = app.DragStartAxesPosition;
            minSize = 0.04;
            if strcmp(app.DragEdge, 'move')
                pos(1) = pos(1) + dx;
                pos(2) = pos(2) + dy;
            else
                if contains(app.DragEdge, 'left')
                    pos(1) = pos(1) + dx;
                    pos(3) = pos(3) - dx;
                end
                if contains(app.DragEdge, 'right')
                    pos(3) = pos(3) + dx;
                end
                if contains(app.DragEdge, 'bottom')
                    pos(2) = pos(2) + dy;
                    pos(4) = pos(4) - dy;
                end
                if contains(app.DragEdge, 'top')
                    pos(4) = pos(4) + dy;
                end
            end
            pos = clampAxesPosition(pos, minSize);
            [pos, guide] = app.snapAxesPosition(idx, pos, app.DragEdge);
            app.AxesPositions(idx, :) = pos;
            app.positionPanelUI();
            app.showSnapGuide(guide);
        end

        function dragPanel(app, point)
            idx = app.DragPanelIndex;
            if isempty(idx) || idx > numel(app.PanelUI)
                return
            end
            canvasRect = app.editorCanvasRect();
            delta = point - app.DragStartPoint;
            dx = delta(1) / max(canvasRect(3), 1);
            dy = delta(2) / max(canvasRect(4), 1);
            pos = app.DragStartPosition;
            minSize = 0.04;
            if strcmp(app.DragEdge, 'move')
                pos(1) = pos(1) + dx;
                pos(2) = pos(2) + dy;
                pos = clampPanelPosition(pos, minSize);
                [pos, guide] = app.snapPanelPosition(idx, pos, app.DragEdge);
                app.PanelPositions(idx, :) = pos;
                app.positionPanelUI();
                app.showSnapGuide(guide);
                return
            end
            if contains(app.DragEdge, 'left')
                pos(1) = pos(1) + dx;
                pos(3) = pos(3) - dx;
            end
            if contains(app.DragEdge, 'right')
                pos(3) = pos(3) + dx;
            end
            if contains(app.DragEdge, 'bottom')
                pos(2) = pos(2) + dy;
                pos(4) = pos(4) - dy;
            end
            if contains(app.DragEdge, 'top')
                pos(4) = pos(4) + dy;
            end
            pos = clampPanelPosition(pos, minSize);
            [pos, guide] = app.snapPanelPosition(idx, pos, app.DragEdge);
            app.PanelPositions(idx, :) = pos;
            app.positionPanelUI();
            app.showSnapGuide(guide);
        end

        function startGraphicDrag(app, h)
            ax = ancestor(h, 'matlab.ui.control.UIAxes');
            if isempty(ax) || ~isgraphics(ax)
                return
            end
            app.DragMode = 'graphic';
            app.DragHandle = h;
            app.DragStartAxesPoint = axesDataPoint(ax);
            app.DragStartGraphicPosition = [];
            app.DragStartXData = [];
            app.DragStartYData = [];
            if isprop(h, 'Position')
                try
                    app.DragStartGraphicPosition = h.Position;
                catch
                end
            end
            if app.isDraggableLine(h)
                try
                    app.DragStartXData = h.XData;
                    app.DragStartYData = h.YData;
                catch
                end
            end
            app.UIFigure.Pointer = 'fleur';
        end

        function graphicMouseDown(app, h)
            app.selectGraphic(h);
            if app.isDraggableGraphic(h)
                app.startGraphicDrag(h);
            end
        end

        function dragGraphic(app)
            h = app.DragHandle;
            if isempty(h) || ~isgraphics(h)
                return
            end
            ax = ancestor(h, 'matlab.ui.control.UIAxes');
            if isempty(ax) || ~isgraphics(ax)
                return
            end
            delta = axesDataPoint(ax) - app.DragStartAxesPoint;
            try
                if app.isDraggableLine(h) && ~isempty(app.DragStartXData)
                    newX = app.DragStartXData + delta(1);
                    newY = app.DragStartYData + delta(2);
                    [newX, newY, guide] = app.snapGraphicLine(h, ax, newX, newY);
                    h.XData = newX;
                    h.YData = newY;
                    app.showSnapGuide(guide);
                elseif isprop(h, 'Position') && ~isempty(app.DragStartGraphicPosition)
                    pos = app.DragStartGraphicPosition;
                    pos(1) = pos(1) + delta(1);
                    pos(2) = pos(2) + delta(2);
                    [pos, guide] = app.snapGraphicPosition(h, ax, pos);
                    h.Position = pos;
                    app.showSnapGuide(guide);
                end
            catch
            end
        end

        function [pos, guide] = snapGraphicPosition(app, h, ax, pos)
            guide = emptyGuide();
            if ~app.snapEnabled()
                return
            end
            movingBounds = graphicBoundsFromPosition(h, pos);
            movingRect = app.dataBoundsToCanvasRect(ax, movingBounds);
            [refs, labels] = app.graphicSnapRefs(h);
            if isempty(refs)
                return
            end
            [xSnap, xDesc] = nearestSnap( ...
                [movingRect(1), movingRect(1) + movingRect(3)/2, movingRect(1) + movingRect(3)], ...
                graphicXRefs(refs), 10, labels, ...
                {'左边界','水平中心','右边界'}, [0, movingRect(3)/2, movingRect(3)]);
            [ySnap, yDesc] = nearestSnap( ...
                [movingRect(2), movingRect(2) + movingRect(4)/2, movingRect(2) + movingRect(4)], ...
                graphicYRefs(refs), 10, labels, ...
                {'下边界','垂直中心','上边界'}, [0, movingRect(4)/2, movingRect(4)]);
            pixelDelta = [0 0];
            if ~isempty(xSnap)
                pixelDelta(1) = xSnap.newStart - movingRect(1);
                guide.x = app.pixelXToCanvasNorm(xSnap.refValue);
                guide.texts(end + 1) = xDesc;
            end
            if ~isempty(ySnap)
                pixelDelta(2) = ySnap.newStart - movingRect(2);
                guide.y = app.pixelYToCanvasNorm(ySnap.refValue);
                guide.texts(end + 1) = yDesc;
            end
            dataDelta = app.canvasPixelDeltaToData(ax, pixelDelta);
            pos(1) = pos(1) + dataDelta(1);
            pos(2) = pos(2) + dataDelta(2);
        end

        function [xData, yData, guide] = snapGraphicLine(app, h, ax, xData, yData)
            guide = emptyGuide();
            if ~app.snapEnabled()
                return
            end
            movingBounds = [min(xData), min(yData), max(xData) - min(xData), max(yData) - min(yData)];
            movingRect = app.dataBoundsToCanvasRect(ax, movingBounds);
            [refs, labels] = app.graphicSnapRefs(h);
            if isempty(refs)
                return
            end
            [xSnap, xDesc] = nearestSnap( ...
                [movingRect(1), movingRect(1) + movingRect(3)/2, movingRect(1) + movingRect(3)], ...
                graphicXRefs(refs), 10, labels, ...
                {'左边界','水平中心','右边界'}, [0, movingRect(3)/2, movingRect(3)]);
            [ySnap, yDesc] = nearestSnap( ...
                [movingRect(2), movingRect(2) + movingRect(4)/2, movingRect(2) + movingRect(4)], ...
                graphicYRefs(refs), 10, labels, ...
                {'下边界','垂直中心','上边界'}, [0, movingRect(4)/2, movingRect(4)]);
            pixelDelta = [0 0];
            if ~isempty(xSnap)
                pixelDelta(1) = xSnap.newStart - movingRect(1);
                guide.x = app.pixelXToCanvasNorm(xSnap.refValue);
                guide.texts(end + 1) = xDesc;
            end
            if ~isempty(ySnap)
                pixelDelta(2) = ySnap.newStart - movingRect(2);
                guide.y = app.pixelYToCanvasNorm(ySnap.refValue);
                guide.texts(end + 1) = yDesc;
            end
            dataDelta = app.canvasPixelDeltaToData(ax, pixelDelta);
            xData = xData + dataDelta(1);
            yData = yData + dataDelta(2);
        end

        function [pos, guide] = snapPanelPosition(app, idx, pos, edgeName)
            guide = emptyGuide();
            if ~app.snapEnabled() || numel(app.PanelPositions) < 2
                return
            end
            canvasRect = app.editorCanvasRect();
            xTol = 10 / max(canvasRect(3), 1);
            yTol = 10 / max(canvasRect(4), 1);
            others = setdiff(1:size(app.PanelPositions, 1), idx);
            refs = app.PanelPositions(others, :);
            labels = strings(numel(others), 1);
            for n = 1:numel(others)
                labels(n) = string(sprintf(app.Panels(others(n)).labelFormat, app.Panels(others(n)).label));
            end

            if strcmp(edgeName, 'move')
                movingX = [pos(1), pos(1) + pos(3)/2, pos(1) + pos(3)];
                movingY = [pos(2), pos(2) + pos(4)/2, pos(2) + pos(4)];
                [xSnap, xDesc] = nearestSnap(movingX, panelXRefs(refs), xTol, labels, ...
                    {'左边缘','水平中心','右边缘'}, [0, pos(3)/2, pos(3)]);
                [ySnap, yDesc] = nearestSnap(movingY, panelYRefs(refs), yTol, labels, ...
                    {'下边缘','垂直中心','上边缘'}, [0, pos(4)/2, pos(4)]);
                if ~isempty(xSnap)
                    pos(1) = xSnap.newStart;
                    guide.x = xSnap.refValue;
                    guide.texts(end + 1) = xDesc;
                end
                if ~isempty(ySnap)
                    pos(2) = ySnap.newStart;
                    guide.y = ySnap.refValue;
                    guide.texts(end + 1) = yDesc;
                end
            else
                if contains(edgeName, 'left') || contains(edgeName, 'right')
                    if contains(edgeName, 'left')
                        movingX = pos(1);
                    else
                        movingX = pos(1) + pos(3);
                    end
                    [xSnap, xDesc] = nearestSnap(movingX, panelXRefs(refs), xTol, labels, {edgeName}, 0);
                    if ~isempty(xSnap)
                        if contains(edgeName, 'left')
                            oldRight = pos(1) + pos(3);
                            pos(1) = xSnap.refValue;
                            pos(3) = oldRight - pos(1);
                        else
                            pos(3) = xSnap.refValue - pos(1);
                        end
                        guide.x = xSnap.refValue;
                        guide.texts(end + 1) = xDesc;
                    end
                end
                if contains(edgeName, 'bottom') || contains(edgeName, 'top')
                    if contains(edgeName, 'bottom')
                        movingY = pos(2);
                    else
                        movingY = pos(2) + pos(4);
                    end
                    [ySnap, yDesc] = nearestSnap(movingY, panelYRefs(refs), yTol, labels, {edgeName}, 0);
                    if ~isempty(ySnap)
                        if contains(edgeName, 'bottom')
                            oldTop = pos(2) + pos(4);
                            pos(2) = ySnap.refValue;
                            pos(4) = oldTop - pos(2);
                        else
                            pos(4) = ySnap.refValue - pos(2);
                        end
                        guide.y = ySnap.refValue;
                        guide.texts(end + 1) = yDesc;
                    end
                end
            end
            pos = clampPanelPosition(pos, 0.04);
        end

        function [pos, guide] = snapAxesPosition(app, idx, pos, edgeName)
            guide = emptyGuide();
            if ~app.snapEnabled() || numel(app.PanelUI) < 2
                return
            end
            canvasRect = app.editorCanvasRect();
            xTol = 10 / max(canvasRect(3), 1);
            yTol = 10 / max(canvasRect(4), 1);
            others = setdiff(1:size(app.AxesPositions, 1), idx);
            refs = zeros(numel(others), 4);
            labels = strings(numel(others), 1);
            for n = 1:numel(others)
                refs(n, :) = app.axesFrameCanvasRect(others(n), app.AxesPositions(others(n), :));
                labels(n) = "Axes " + string(sprintf(app.Panels(others(n)).labelFormat, app.Panels(others(n)).label));
            end
            if isempty(refs)
                return
            end
            outer = app.axesOuterCanvasRect(idx, pos);
            moving = app.axesFrameCanvasRect(idx, pos);
            if strcmp(edgeName, 'move')
                movingX = [moving(1), moving(1) + moving(3)/2, moving(1) + moving(3)];
                movingY = [moving(2), moving(2) + moving(4)/2, moving(2) + moving(4)];
                [xSnap, xDesc] = nearestSnap(movingX, axesFrameXRefs(refs), xTol, labels, ...
                    {'plot left frame','plot horizontal center','plot right frame'}, [0, moving(3)/2, moving(3)]);
                [ySnap, yDesc] = nearestSnap(movingY, axesFrameYRefs(refs), yTol, labels, ...
                    {'plot bottom frame','plot vertical center','plot top frame'}, [0, moving(4)/2, moving(4)]);
                if ~isempty(xSnap)
                    dx = xSnap.newStart - moving(1);
                    outer(1) = outer(1) + dx;
                    guide.x = xSnap.refValue;
                    guide.texts(end + 1) = xDesc;
                end
                if ~isempty(ySnap)
                    dy = ySnap.newStart - moving(2);
                    outer(2) = outer(2) + dy;
                    guide.y = ySnap.refValue;
                    guide.texts(end + 1) = yDesc;
                end
            else
                if contains(edgeName, 'left') || contains(edgeName, 'right')
                    if contains(edgeName, 'left')
                        movingX = moving(1);
                    else
                        movingX = moving(1) + moving(3);
                    end
                    [xSnap, xDesc] = nearestSnap(movingX, axesFrameXRefs(refs), xTol, labels, {edgeName}, 0);
                    if ~isempty(xSnap)
                        if contains(edgeName, 'left')
                            dx = xSnap.refValue - moving(1);
                            outer(1) = outer(1) + dx;
                            outer(3) = outer(3) - dx;
                        else
                            dx = xSnap.refValue - (moving(1) + moving(3));
                            outer(3) = outer(3) + dx;
                        end
                        guide.x = xSnap.refValue;
                        guide.texts(end + 1) = xDesc;
                    end
                end
                if contains(edgeName, 'bottom') || contains(edgeName, 'top')
                    if contains(edgeName, 'bottom')
                        movingY = moving(2);
                    else
                        movingY = moving(2) + moving(4);
                    end
                    [ySnap, yDesc] = nearestSnap(movingY, axesFrameYRefs(refs), yTol, labels, {edgeName}, 0);
                    if ~isempty(ySnap)
                        if contains(edgeName, 'bottom')
                            dy = ySnap.refValue - moving(2);
                            outer(2) = outer(2) + dy;
                            outer(4) = outer(4) - dy;
                        else
                            dy = ySnap.refValue - (moving(2) + moving(4));
                            outer(4) = outer(4) + dy;
                        end
                        guide.y = ySnap.refValue;
                        guide.texts(end + 1) = yDesc;
                    end
                end
            end
            pos = clampAxesPosition(app.axesRelativeFromCanvas(idx, outer), 0.04);
        end

        function rect = axesOuterCanvasRect(app, idx, relPos)
            panel = app.PanelPositions(idx, :);
            rect = [panel(1) + relPos(1)*panel(3), panel(2) + relPos(2)*panel(4), ...
                relPos(3)*panel(3), relPos(4)*panel(4)];
        end

        function rect = axesFrameCanvasRect(app, idx, relPos)
            outer = app.axesOuterCanvasRect(idx, relPos);
            canvasRect = app.editorCanvasRect();
            currentOuter = app.axesOuterCanvasRect(idx, app.AxesPositions(idx, :));
            currentFrame = normalizeCanvasRect(app.axesFramePixelRect(idx), canvasRect);
            inset = [currentFrame(1) - currentOuter(1), ...
                currentFrame(2) - currentOuter(2), ...
                currentOuter(1) + currentOuter(3) - currentFrame(1) - currentFrame(3), ...
                currentOuter(2) + currentOuter(4) - currentFrame(2) - currentFrame(4)];
            rect = [outer(1) + inset(1), outer(2) + inset(2), ...
                outer(3) - inset(1) - inset(3), outer(4) - inset(2) - inset(4)];
            rect(3:4) = max(rect(3:4), [0.001 0.001]);
        end

        function rect = axesFramePixelRect(app, idx)
            panelRect = getpixelposition(app.PanelUI(idx).Container, true);
            rect = childRectFromPosition(panelRect, app.axesFramePositionInPanel(idx));
        end

        function pos = axesFramePositionInPanel(app, idx)
            ax = app.PanelUI(idx).Axes;
            pos = ax.Position;
            try
                oldUnits = ax.Units;
                ax.Units = 'pixels';
                restoreUnits = onCleanup(@() set(ax, 'Units', oldUnits));
                innerPos = ax.InnerPosition;
                if numel(innerPos) == 4 && all(isfinite(innerPos)) && all(innerPos(3:4) > 0)
                    pos = innerPos;
                end
                clear restoreUnits
            catch
            end
        end

        function relPos = axesRelativeFromCanvas(app, idx, rect)
            panel = app.PanelPositions(idx, :);
            relPos = [(rect(1) - panel(1)) / max(panel(3), eps), ...
                (rect(2) - panel(2)) / max(panel(4), eps), ...
                rect(3) / max(panel(3), eps), rect(4) / max(panel(4), eps)];
        end

        function [pos, guide] = snapLabelPosition(app, idx, pos)
            guide = emptyGuide();
            if ~app.snapEnabled() || numel(app.PanelUI) < 2
                return
            end
            containerRect = getpixelposition(app.PanelUI(idx).Container, true);
            labelRect = [containerRect(1) + pos(1)*containerRect(3), ...
                containerRect(2) + pos(2)*containerRect(4), ...
                pos(3)*containerRect(3), pos(4)*containerRect(4)];
            movingX = [labelRect(1), labelRect(1) + labelRect(3)/2, labelRect(1) + labelRect(3)];
            movingY = [labelRect(2), labelRect(2) + labelRect(4)/2, labelRect(2) + labelRect(4)];
            refRects = [];
            refLabels = strings(0);
            for k = setdiff(1:numel(app.PanelUI), idx)
                if isgraphics(app.PanelUI(k).Label)
                    refRects(end + 1, :) = getpixelposition(app.PanelUI(k).Label, true); %#ok<AGROW>
                    refLabels(end + 1) = string(sprintf(app.Panels(k).labelFormat, app.Panels(k).label)); %#ok<AGROW>
                end
            end
            if isempty(refRects)
                return
            end
            [xSnap, xDesc] = nearestSnap(movingX, rectXRefs(refRects), 8, refLabels, ...
                {'左边缘','水平中心','右边缘'}, [0, labelRect(3)/2, labelRect(3)]);
            [ySnap, yDesc] = nearestSnap(movingY, rectYRefs(refRects), 8, refLabels, ...
                {'下边缘','垂直中心','上边缘'}, [0, labelRect(4)/2, labelRect(4)]);
            canvasRect = app.editorCanvasRect();
            if ~isempty(xSnap)
                labelRect(1) = xSnap.newStart;
                pos(1) = (labelRect(1) - containerRect(1)) / max(containerRect(3), 1);
                guide.x = (xSnap.refValue - canvasRect(1)) / max(canvasRect(3), 1);
                guide.texts(end + 1) = xDesc;
            end
            if ~isempty(ySnap)
                labelRect(2) = ySnap.newStart;
                pos(2) = (labelRect(2) - containerRect(2)) / max(containerRect(4), 1);
                guide.y = (ySnap.refValue - canvasRect(2)) / max(canvasRect(4), 1);
                guide.texts(end + 1) = yDesc;
            end
            pos(1) = min(max(pos(1), 0), max(0, 1 - pos(3)));
            pos(2) = min(max(pos(2), 0), max(0, 1 - pos(4)));
        end

        function [refs, labels] = graphicSnapRefs(app, movingHandle)
            refs = [];
            labels = strings(0);
            for k = 1:numel(app.PanelUI)
                ax = app.PanelUI(k).Axes;
                if ~isgraphics(ax)
                    continue
                end
                handles = [findall(ax); ax.Title; ax.XLabel; ax.YLabel; ax.ZLabel];
                for i = 1:numel(handles)
                    h = handles(i);
                    if isempty(h) || ~isgraphics(h) || isequal(h, movingHandle) || h == ax
                        continue
                    end
                    if ~app.isDraggableGraphic(h)
                        continue
                    end
                    bounds = graphicBounds(h);
                    if any(~isfinite(bounds)) || bounds(3) < 0 || bounds(4) < 0
                        continue
                    end
                    refs(end + 1, :) = app.dataBoundsToCanvasRect(ax, bounds); %#ok<AGROW>
                    labels(end + 1) = string(graphicSnapLabel(h)); %#ok<AGROW>
                end
            end
        end

        function rect = dataBoundsToCanvasRect(app, ax, bounds)
            p1 = app.dataPointToCanvasPixel(ax, bounds(1), bounds(2));
            p2 = app.dataPointToCanvasPixel(ax, bounds(1) + bounds(3), bounds(2) + bounds(4));
            x1 = min(p1(1), p2(1));
            x2 = max(p1(1), p2(1));
            y1 = min(p1(2), p2(2));
            y2 = max(p1(2), p2(2));
            rect = [x1, y1, x2 - x1, y2 - y1];
        end

        function point = dataPointToCanvasPixel(~, ax, xValue, yValue)
            axRect = axesFramePixelRectForAxes(ax);
            tx = (xValue - ax.XLim(1)) / diff(ax.XLim);
            ty = (yValue - ax.YLim(1)) / diff(ax.YLim);
            if strcmp(ax.XDir, 'reverse')
                tx = 1 - tx;
            end
            if strcmp(ax.YDir, 'reverse')
                ty = 1 - ty;
            end
            point = [axRect(1) + tx * axRect(3), axRect(2) + ty * axRect(4)];
        end

        function dataDelta = canvasPixelDeltaToData(~, ax, pixelDelta)
            axRect = axesFramePixelRectForAxes(ax);
            dataDelta = [pixelDelta(1) * diff(ax.XLim) / max(axRect(3), 1), ...
                pixelDelta(2) * diff(ax.YLim) / max(axRect(4), 1)];
            if strcmp(ax.XDir, 'reverse')
                dataDelta(1) = -dataDelta(1);
            end
            if strcmp(ax.YDir, 'reverse')
                dataDelta(2) = -dataDelta(2);
            end
        end

        function xNorm = pixelXToCanvasNorm(app, pixelX)
            canvasRect = app.editorCanvasRect();
            xNorm = (pixelX - canvasRect(1)) / max(canvasRect(3), 1);
        end

        function yNorm = pixelYToCanvasNorm(app, pixelY)
            canvasRect = app.editorCanvasRect();
            yNorm = (pixelY - canvasRect(2)) / max(canvasRect(4), 1);
        end

        function enabled = snapEnabled(app)
            enabled = false;
            try
                enabled = strcmp(app.SnapSwitch.Value, '开');
            catch
            end
        end

        function showSnapGuide(app, guide)
            if isempty(guide.texts)
                app.hideSnapGuides();
                return
            end
            displaySize = app.displayCanvasSize();
            canvasPos = [0 0 displaySize(1) displaySize(2)];
            if ~isnan(guide.x) && isgraphics(app.SnapVLine)
                app.SnapVLine.Position = [guide.x * canvasPos(3) - 1, 0, 2, canvasPos(4)];
                app.SnapVLine.Visible = 'on';
            elseif isgraphics(app.SnapVLine)
                app.SnapVLine.Visible = 'off';
            end
            if ~isnan(guide.y) && isgraphics(app.SnapHLine)
                app.SnapHLine.Position = [0, guide.y * canvasPos(4) - 1, canvasPos(3), 2];
                app.SnapHLine.Visible = 'on';
            elseif isgraphics(app.SnapHLine)
                app.SnapHLine.Visible = 'off';
            end
            if isgraphics(app.SnapGuideText)
                textValue = "吸附: " + strjoin(guide.texts, " / ");
                app.SnapGuideText.Text = char(textValue);
                app.SnapGuideText.Position = [8, max(8, canvasPos(4) - 30), ...
                    min(canvasPos(3) - 16, 520), 24];
                app.SnapGuideText.Visible = 'on';
                app.setStatus(char(textValue));
            end
        end

        function hideSnapGuides(app)
            if isgraphics(app.SnapVLine)
                app.SnapVLine.Visible = 'off';
            end
            if isgraphics(app.SnapHLine)
                app.SnapHLine.Visible = 'off';
            end
            if isgraphics(app.SnapGuideText)
                app.SnapGuideText.Visible = 'off';
            end
        end

        function tf = isDraggableGraphic(app, h)
            tf = false;
            if isempty(h) || ~isgraphics(h) || app.isCanvasAxes(h)
                return
            end
            if isa(h, 'matlab.graphics.primitive.Text') || isa(h, 'matlab.graphics.primitive.Rectangle')
                tf = true;
                return
            end
            tf = app.isDraggableLine(h);
        end

        function tf = isDraggableLine(~, h)
            tf = false;
            if isempty(h) || ~isgraphics(h) || ~isa(h, 'matlab.graphics.chart.primitive.Line')
                return
            end
            try
                tf = strcmp(h.Tag, 'gfc_draggable') || strcmp(h.DisplayName, 'scale_bar');
            catch
            end
        end

        function newLayout(app)
            app.Rows = round(app.RowsSpinner.Value);
            app.Cols = round(app.ColsSpinner.Value);
            app.CanvasWidthPx = round(app.CanvasWidthField.Value);
            app.CanvasHeightPx = round(app.CanvasHeightField.Value);
            app.LayoutGap = app.GapField.Value;
            app.LayoutMargin = app.MarginField.Value;
            app.applyFixedWindowSize();
            app.Panels = gfc.createPanels(app.Rows, app.Cols);
            app.resetLayoutPositions();
            app.AssetInfos = app.blankAssetInfos(numel(app.Panels));
            app.SelectedPanelId = app.Panels(1).id;
            app.rebuildCanvas();
            app.refreshTree();
            app.setStatus(sprintf('已新建 %d 行 x %d 列布局。', app.Rows, app.Cols));
        end

        function mergeRange(app)
            try
                [app.Panels, merged] = gfc.mergePanels(app.Panels, ...
                    round(app.MergeRowSpinner.Value), round(app.MergeColSpinner.Value), ...
                    round(app.MergeRowSpanSpinner.Value), round(app.MergeColSpanSpinner.Value));
                app.resetLayoutPositions();
                app.AssetInfos = app.blankAssetInfos(numel(app.Panels));
                app.SelectedPanelId = merged.id;
                app.rebuildCanvas();
                app.refreshTree();
                app.setStatus('已合并区域。提示：合并后请重新导入该 panel 的素材。');
            catch ME
                uialert(app.UIFigure, ME.message, '合并失败');
            end
        end

        function unmergeSelected(app)
            try
                app.Panels = gfc.unmergePanel(app.Panels, app.SelectedPanelId);
                app.resetLayoutPositions();
                app.AssetInfos = app.blankAssetInfos(numel(app.Panels));
                app.SelectedPanelId = app.Panels(1).id;
                app.rebuildCanvas();
                app.refreshTree();
                app.setStatus('已取消合并。提示：拆分后请重新导入相关素材。');
            catch ME
                uialert(app.UIFigure, ME.message, '取消合并失败');
            end
        end

        function rebuildCanvas(app)
            delete(app.CanvasPanel.Children);
            app.PanelUI = struct('PanelId', {}, 'Container', {}, 'Axes', {}, 'Button', {}, 'Label', {});
            app.ensureLayoutState();
            for k = 1:numel(app.Panels)
                p = uipanel(app.CanvasPanel, 'Title', '', 'BackgroundColor', [1 1 1], ...
                    'BorderType', 'line', 'HighlightColor', app.Panels(k).borderColor, ...
                    'ButtonDownFcn', @(src, ~) app.startPanelMove(app.containerIndex(src), app.UIFigure.CurrentPoint));
                ax = uiaxes(p, 'Box', 'on');
                ax.ButtonDownFcn = @(~, ~) app.selectPanel(app.Panels(k).id);
                ax.TickDir = 'in';
                btn = uibutton(p, 'Text', '+', 'FontSize', 18, ...
                    'ButtonPushedFcn', @(~, ~) app.importPanel(app.Panels(k).id));
                lbl = uilabel(p, 'Text', sprintf(app.Panels(k).labelFormat, app.Panels(k).label), ...
                    'FontWeight', 'bold', 'FontSize', 13, 'BackgroundColor', [1 1 1]);
                app.PanelUI(k) = struct('PanelId', app.Panels(k).id, 'Container', p, ...
                    'Axes', ax, 'Button', btn, 'Label', lbl);
            end
            app.createSnapGuides();
            app.positionPanelUI();
            app.selectPanel(app.SelectedPanelId);
        end

        function createSnapGuides(app)
            app.SnapVLine = uilabel(app.CanvasPanel, 'Text', '', ...
                'BackgroundColor', [0.05 0.42 0.90], 'Visible', 'off');
            app.SnapHLine = uilabel(app.CanvasPanel, 'Text', '', ...
                'BackgroundColor', [0.05 0.42 0.90], 'Visible', 'off');
            app.SnapGuideText = uilabel(app.CanvasPanel, 'Text', '', ...
                'BackgroundColor', [1.00 0.96 0.72], 'FontColor', [0.12 0.14 0.18], ...
                'FontSize', 11, 'Visible', 'off');
        end

        function positionPanelUI(app)
            if isempty(app.CanvasPanel) || ~isvalid(app.CanvasPanel) || isempty(app.PanelUI)
                return
            end
            app.ensureLayoutState();
            displaySize = app.displayCanvasSize();
            W = max(displaySize(1), 10);
            H = max(displaySize(2), 10);
            pos = app.PanelPositions;
            for k = 1:numel(app.PanelUI)
                if ~isvalid(app.PanelUI(k).Container)
                    continue
                end
                px = [pos(k,1)*W, pos(k,2)*H, pos(k,3)*W, pos(k,4)*H];
                px(3:4) = max(px(3:4), [80 70]);
                app.PanelUI(k).Container.Position = px;
                ap = clampAxesPosition(app.AxesPositions(k, :), 0.04);
                app.AxesPositions(k, :) = ap;
                app.PanelUI(k).Axes.Position = [ap(1)*px(3), ap(2)*px(4), ...
                    ap(3)*px(3), ap(4)*px(4)];
                if strlength(string(app.Panels(k).sourcePath)) == 0
                    app.PanelUI(k).Button.Position = [max(8, px(3)/2-18) max(8, px(4)/2-18) 36 36];
                else
                    app.PanelUI(k).Button.Position = [max(8, px(3)-34), 6, 28, 28];
                end
                lp = app.LabelPositions(k, :);
                app.PanelUI(k).Label.Position = [lp(1)*px(3), lp(2)*px(4), ...
                    max(28, lp(3)*px(3)), max(18, lp(4)*px(4))];
            end
        end

        function selectPanel(app, panelId)
            app.SelectedPanelId = panelId;
            idx = app.panelIndex(panelId);
            if isempty(idx)
                return
            end
            app.clearSelectionHighlight();
            app.SelectedHandle = app.PanelUI(idx).Axes;
            app.LabelField.Value = app.Panels(idx).label;
            app.LabelFormatDropDown.Value = app.Panels(idx).labelFormat;
            for k = 1:numel(app.PanelUI)
                if app.PanelUI(k).PanelId == panelId
                    app.PanelUI(k).Container.BackgroundColor = [0.93 0.97 1.00];
                else
                    app.PanelUI(k).Container.BackgroundColor = [1 1 1];
                end
            end
            app.showPropertiesForPanel(idx);
            app.updateLineStyleControls(app.PanelUI(idx).Axes);
        end

        function importSelected(app)
            app.importPanel(app.SelectedPanelId);
        end

        function importPanel(app, panelId)
            idx = app.panelIndex(panelId);
            if isempty(idx)
                return
            end
            [file, path] = uigetfile({'*.fig;*.svg;*.png;*.jpg;*.jpeg;*.tif;*.tiff;*.bmp', ...
                '支持的素材 (*.fig, *.svg, *.png, *.jpg, *.tif, *.bmp)'}, '导入素材');
            if isequal(file, 0)
                return
            end
            filename = fullfile(path, file);
            app.selectPanel(panelId);
            try
                report = app.importFileToPanel(idx, filename, true);
                app.setStatus(report);
            catch ME
                uialert(app.UIFigure, ME.message, '瀵煎叆澶辫触');
            end
            %{
            ax = app.PanelUI(idx).Axes;
            [~, ~, ext] = fileparts(filename);
            ext = lower(ext);
            try
                switch ext
                    case '.fig'
                        report = gfc.importFigToAxes(ax, filename);
                        assetType = 'fig';
                    case '.svg'
                        report = gfc.importSvgToAxes(ax, filename, 'AllowInkscapeFallback', true);
                        assetType = 'svg';
                    case {'.png','.jpg','.jpeg','.tif','.tiff','.bmp'}
                        report = gfc.importRasterToAxes(ax, filename, 'AutoCrop', true);
                        assetType = 'raster';
                    otherwise
                        error('不支持的素材格式: %s', ext);
                end
                app.PanelUI(idx).Button.Text = '+';
                app.PanelUI(idx).Button.Position(3:4) = [28 28];
                app.PanelUI(idx).Button.Position(1:2) = [app.PanelUI(idx).Container.Position(3)-34, 6];
                app.Panels(idx).sourcePath = filename;
                app.Panels(idx).assetType = assetType;
                app.Panels(idx).importReport = report;
                app.AssetInfos(idx) = struct('sourcePath', filename, 'assetType', assetType, 'importReport', report);
                app.attachObjectCallbacks(ax);
                app.syncCanvasStyle();
                app.refreshTree();
                app.setStatus(report);
            catch ME
                uialert(app.UIFigure, ME.message, '导入失败');
            end
        end

        end

            %}

        end

        function report = importFileToPanel(app, idx, filename, doStyle)
            if nargin < 4
                doStyle = true;
            end
            if isempty(idx) || idx > numel(app.PanelUI) || ~isfile(filename)
                error('gfc:importFileToPanel:MissingFile', '素材文件不存在或 panel 无效: %s', filename);
            end
            ax = app.PanelUI(idx).Axes;
            [~, ~, ext] = fileparts(filename);
            ext = lower(ext);
            switch ext
                case '.fig'
                    report = gfc.importFigToAxes(ax, filename);
                    assetType = 'fig';
                case '.svg'
                    report = gfc.importSvgToAxes(ax, filename, 'AllowInkscapeFallback', true);
                    assetType = 'svg';
                case {'.png','.jpg','.jpeg','.tif','.tiff','.bmp'}
                    report = gfc.importRasterToAxes(ax, filename, 'AutoCrop', true);
                    assetType = 'raster';
                otherwise
                    error('gfc:importFileToPanel:UnsupportedFile', '不支持的素材格式: %s', ext);
            end
            app.PanelUI(idx).Button.Text = '+';
            app.PanelUI(idx).Button.Position(3:4) = [28 28];
            app.PanelUI(idx).Button.Position(1:2) = [app.PanelUI(idx).Container.Position(3)-34, 6];
            app.Panels(idx).sourcePath = filename;
            app.Panels(idx).assetType = assetType;
            app.Panels(idx).importReport = report;
            app.AssetInfos(idx) = struct('sourcePath', filename, 'assetType', assetType, 'importReport', report);
            app.attachObjectCallbacks(ax);
            if doStyle
                app.syncCanvasStyle();
            end
            app.refreshTree();
        end

        function attachObjectCallbacks(app, ax)
            objs = [findall(ax); ax.Title; ax.XLabel; ax.YLabel; ax.ZLabel];
            for h = reshape(objs, 1, [])
                try
                    if h == ax
                        continue
                    end
                    h.ButtonDownFcn = @(src, ~) app.graphicMouseDown(src);
                    h.HitTest = 'on';
                    h.PickableParts = 'all';
                    h.ContextMenu = app.ObjectContextMenu;
                catch
                end
            end
        end

        function selectGraphic(app, h)
            if isempty(h) || ~isgraphics(h)
                return
            end
            app.clearSelectionHighlight();
            app.SelectedHandle = h;
            app.highlightSelectedHandle(h);
            app.showPropertiesForHandle(h);
            app.updateLineStyleControls(h);
            app.setStatus(['已选中: ' objectLabel(h)]);
        end

        function clearSelectionHighlight(app)
            h = app.HighlightedHandle;
            if ~isempty(h) && isgraphics(h)
                try
                    if isprop(h, 'Selected')
                        h.Selected = 'off';
                    end
                catch
                end
            end
            app.HighlightedHandle = [];
        end

        function highlightSelectedHandle(app, h)
            app.HighlightedHandle = h;
            try
                if isprop(h, 'Selected')
                    h.Selected = 'on';
                end
                if isprop(h, 'SelectionHighlight')
                    h.SelectionHighlight = 'on';
                end
            catch
            end
        end

        function deleteSelectedGraphic(app)
            h = app.SelectedHandle;
            if isempty(h) || ~isgraphics(h)
                app.setStatus('没有选中的可删除图元。');
                return
            end
            if isa(h, 'matlab.ui.control.UIAxes') || app.isCanvasAxes(h)
                app.setStatus('坐标轴不能直接删除；请删除坐标轴内的具体图元。');
                return
            end
            ax = ancestor(h, 'matlab.ui.control.UIAxes');
            try
                delete(h);
                app.SelectedHandle = [];
                app.HighlightedHandle = [];
                if ~isempty(ax) && isgraphics(ax)
                    app.SelectedHandle = ax;
                    app.showPropertiesForHandle(ax);
                end
                app.refreshTree();
                app.setStatus('已删除选中图元。');
            catch ME
                uialert(app.UIFigure, ME.message, '删除失败');
            end
        end

        function applyPanelLabel(app)
            idx = app.panelIndex(app.SelectedPanelId);
            if isempty(idx)
                return
            end
            app.Panels(idx).label = app.LabelField.Value;
            app.Panels(idx).labelFormat = app.LabelFormatDropDown.Value;
            app.PanelUI(idx).Label.Text = sprintf(app.Panels(idx).labelFormat, app.Panels(idx).label);
            app.refreshTree();
            app.showPropertiesForPanel(idx);
        end

        function styleAll(app)
            app.syncCanvasStyle();
            app.refreshTree();
            app.setStatus(sprintf('已统一字体为 %s，字号为 %g。', app.StyleFontName, app.StyleFontSize));
        end

        function alignAxesFrames(app)
            try
                app.ensureLayoutState();
                app.syncCanvasStyle(false);
                for pass = 1:2
                    app.positionPanelUI();
                    drawnow
                    canvasRect = app.editorCanvasRect();
                    frameRects = zeros(numel(app.PanelUI), 4);
                    for k = 1:numel(app.PanelUI)
                        frameRects(k, :) = normalizeCanvasRect(app.axesFramePixelRect(k), canvasRect);
                    end
                    app.AxesPositions = gfc.alignFrameGrid(app.Panels, ...
                        app.PanelPositions, app.AxesPositions, frameRects);
                end
                app.positionPanelUI();
                app.refreshTree();
                app.setStatus('已按行/列自动对齐绘图区框线；预览和导出会使用调整后的 axes 位置。');
            catch ME
                uialert(app.UIFigure, ME.message, '自动对齐失败');
            end
        end

        function syncCanvasStyle(app, applyChildLineWidth)
            if nargin < 2
                applyChildLineWidth = true;
            end
            if ~isempty(app.FontDropDown) && isvalid(app.FontDropDown)
                app.StyleFontName = app.FontDropDown.Value;
            end
            if ~isempty(app.FontSizeSpinner) && isvalid(app.FontSizeSpinner)
                app.StyleFontSize = app.FontSizeSpinner.Value;
            end
            axesList = app.axesList();
            gfc.styleAxes(axesList, 'FontName', app.StyleFontName, ...
                'FontSize', app.StyleFontSize, 'LineWidth', 1, 'Box', 'on', 'TickDir', 'in', ...
                'ApplyChildLineWidth', applyChildLineWidth);
            for k = 1:numel(app.PanelUI)
                try
                    app.PanelUI(k).Container.HighlightColor = app.Panels(k).borderColor;
                    app.PanelUI(k).Label.FontName = app.StyleFontName;
                    app.PanelUI(k).Label.FontSize = app.StyleFontSize + 2;
                catch
                end
            end
            drawnow limitrate
        end

        function importPalette(app)
            [file, path] = uigetfile({'*.png;*.jpg;*.jpeg;*.tif;*.tiff;*.bmp', '色卡图片'}, '导入色卡');
            if isequal(file, 0)
                return
            end
            try
                app.Palette = gfc.paletteFromImage(fullfile(path, file), 6);
                app.updatePaletteSwatches();
                app.setStatus(sprintf('已从色卡提取 %d 个颜色。', size(app.Palette, 1)));
            catch ME
                uialert(app.UIFigure, ME.message, '色卡导入失败');
            end
        end

        function chooseBuiltinPalette(app)
            try
                app.Palette = gfc.builtinPalettes(app.PaletteDropDown.Value, 10);
                app.updatePaletteSwatches();
                app.setStatus(['已选择色卡: ' app.PaletteDropDown.Value]);
            catch ME
                uialert(app.UIFigure, ME.message, '色卡选择失败');
            end
        end

        function applyPalette(app)
            if isempty(app.Palette)
                uialert(app.UIFigure, '请先导入色卡。', '缺少色卡');
                return
            end
            changed = gfc.applyPalette(app.axesList(), app.Palette, 'order', 'Target', 'allLines');
            app.refreshTree();
            app.setStatus(sprintf('已按色卡顺序更新 %d 条谱线。', changed));
        end

        function applyPaletteToSelected(app)
            if isempty(app.Palette)
                uialert(app.UIFigure, '请先选择或导入色卡。', '缺少色卡');
                return
            end
            app.applySwatchColor(1);
        end

        function applySwatchColor(app, idx)
            if isempty(app.Palette) || idx > size(app.Palette, 1)
                return
            end
            h = app.SelectedHandle;
            if isempty(h) || ~isgraphics(h) || app.isCanvasAxes(h)
                uialert(app.UIFigure, '请先选中一条谱线、散点、文字、矩形框或比例尺。', '未选中图元');
                return
            end
            if gfc.applyObjectColor(h, app.Palette(idx, :))
                app.showPropertiesForHandle(h);
                app.refreshTree();
                app.setStatus(sprintf('已应用色卡颜色 #%d 到选中图元。', idx));
            else
                app.setStatus('当前选中对象没有可直接修改的颜色属性。');
            end
        end

        function updateLineStyleControls(app, h)
            if isempty(app.LineStyleDropDown) || ~isvalid(app.LineStyleDropDown) || ...
                    isempty(app.LineWidthSpinner) || ~isvalid(app.LineWidthSpinner)
                return
            end
            canStyle = ~isempty(h) && isgraphics(h) && isprop(h, 'LineStyle');
            canWidth = ~isempty(h) && isgraphics(h) && isprop(h, 'LineWidth');
            if canStyle
                app.LineStyleDropDown.Enable = 'on';
            else
                app.LineStyleDropDown.Enable = 'off';
            end
            if canWidth
                app.LineWidthSpinner.Enable = 'on';
            else
                app.LineWidthSpinner.Enable = 'off';
            end
            if canStyle
                try
                    styleValue = char(h.LineStyle);
                    if any(strcmp(styleValue, app.lineStyleItems()))
                        app.LineStyleDropDown.Value = styleValue;
                    end
                catch
                end
            end
            if canWidth
                try
                    app.LineWidthSpinner.Value = max(app.LineWidthSpinner.Limits(1), ...
                        min(app.LineWidthSpinner.Limits(2), h.LineWidth));
                catch
                end
            end
        end

        function applyLineStyleToSelected(app)
            if isempty(app.LineStyleDropDown) || ~isvalid(app.LineStyleDropDown) || ...
                    isempty(app.LineWidthSpinner) || ~isvalid(app.LineWidthSpinner)
                return
            end
            h = app.SelectedHandle;
            if isempty(h) || ~isgraphics(h)
                return
            end
            changed = gfc.applyLineStyle(h, 'LineStyle', app.LineStyleDropDown.Value, ...
                'LineWidth', app.LineWidthSpinner.Value);
            if changed > 0
                app.showPropertiesForHandle(h);
                app.refreshTree();
                app.setStatus(sprintf('已更新线形 %s、线宽 %.2f。', ...
                    app.LineStyleDropDown.Value, app.LineWidthSpinner.Value));
            else
                app.setStatus('当前选中对象没有可修改的 LineStyle 或 LineWidth。');
            end
        end

        function previewSelectedColormap(app)
            ax = app.currentAxes();
            if isempty(ax) || ~isgraphics(ax)
                return
            end
            if app.axesHasMapObjects(ax)
                app.applyMapColormap(false, true);
            end
        end

        function applyMapColormap(app, usePanel, quiet)
            if nargin < 3
                quiet = false;
            end
            if usePanel
                ax = app.selectedPanelAxes();
            else
                ax = app.currentAxes();
            end
            if isempty(ax) || ~isgraphics(ax)
                uialert(app.UIFigure, '请先选中一个 panel、axes 或 map 图元。', '未选中 axes');
                return
            end
            try
                cmap = gfc.builtinPalettes(app.MapDropDown.Value, 256);
                if app.MapReverseCheckBox.Value
                    cmap = flipud(cmap);
                end
                colormap(ax, cmap);
                climValue = app.parseCLimValue();
                if ~isempty(climValue)
                    ax.CLim = climValue;
                end
                if ~quiet
                    suffix = "";
                    if ~app.axesHasMapObjects(ax)
                        suffix = "（当前 axes 未检测到 image/surface/CData 对象，但 colormap 已设置）";
                    end
                    app.setStatus("已应用 colormap: " + string(app.MapDropDown.Value) + suffix);
                end
            catch ME
                uialert(app.UIFigure, ME.message, 'Colormap 应用失败');
            end
        end

        function editCustomMapStops(app)
            defaultPositions = mat2str(app.CustomMapPositions(:).', 5);
            defaultColors = mat2str(app.CustomMapColors, 5);
            answer = inputdlg({'色轴位置，例如 [0 0.2 1] 或 [300 500 900]', ...
                'RGB 矩阵，每行一个颜色，例如 [0 0 1; 1 1 1; 1 0 0]'}, ...
                '编辑 colormap 控制点', [1 72; 4 72], {defaultPositions, defaultColors});
            if isempty(answer)
                return
            end
            try
                positions = str2num(answer{1}); %#ok<ST2NM>
                colors = str2num(answer{2}); %#ok<ST2NM>
                if isempty(positions) || isempty(colors)
                    error('gfc:CustomMap:EmptyInput', '位置和 RGB 矩阵不能为空。');
                end
                positions = positions(:);
                if size(colors, 2) ~= 3 || size(colors, 1) ~= numel(positions)
                    error('gfc:CustomMap:SizeMismatch', 'RGB 矩阵必须是 N x 3，且 N 与位置数量一致。');
                end
                gfc.controlPointColormap(colors, positions, 8);
                app.CustomMapPositions = positions;
                app.CustomMapColors = min(max(colors, 0), 1);
                app.createCustomMapControls();
                app.setStatus(sprintf('已更新 %d 个 colormap 控制点。', numel(positions)));
            catch ME
                uialert(app.UIFigure, ME.message, '控制点设置失败');
            end
        end

        function chooseCustomMapColor(app, idx)
            try
                color = uisetcolor(app.CustomMapColors(idx, :), sprintf('选择三色 colormap 颜色 %d', idx));
                if isnumeric(color) && numel(color) == 3
                    app.CustomMapColors(idx, :) = min(max(color(:).', 0), 1);
                    app.updateCustomMapButtons();
                    app.setStatus(sprintf('已更新三色 colormap 的第 %d 个颜色。', idx));
                end
            catch ME
                uialert(app.UIFigure, ME.message, '颜色选择失败');
            end
        end

        function applyCustomColormap(app, usePanel)
            if usePanel
                ax = app.selectedPanelAxes();
            else
                ax = app.currentAxes();
            end
            if isempty(ax) || ~isgraphics(ax)
                uialert(app.UIFigure, '请先选中一个 axes 或 panel。', '未选中 axes');
                return
            end
            try
                cmap = gfc.controlPointColormap(app.CustomMapColors, app.CustomMapPositions, app.CustomMapCount);
                colormap(ax, cmap);
                climValue = app.parseCLimValue();
                if ~isempty(climValue)
                    ax.CLim = climValue;
                end
                app.setStatus('已应用三色插值 colormap。');
            catch ME
                uialert(app.UIFigure, ME.message, '三色 colormap 应用失败');
            end
        end

        function addLegend(app)
            ax = app.currentAxes();
            if isempty(ax) || ~isgraphics(ax)
                return
            end
            try
                objects = gfc.legendObjects(ax);
                if isempty(objects)
                    error('gfc:addStyledLegend:NoObjects', '当前 axes 中没有可加入图例的数据对象。');
                end
                names = app.legendChoiceNames(objects);
                [selected, ok] = listdlg('PromptString', '选择要显示在图例中的对象', ...
                    'SelectionMode', 'multiple', 'ListString', cellstr(names), ...
                    'InitialValue', 1:numel(objects), 'ListSize', [320 220], ...
                    'Name', '自定义图例');
                if ~ok || isempty(selected)
                    return
                end
                lgd = gfc.addStyledLegend(ax, 'FontName', app.StyleFontName, ...
                    'FontSize', app.StyleFontSize, 'Objects', objects(selected));
                app.attachObjectCallbacks(ax);
                app.refreshTree();
                app.selectGraphic(lgd);
                app.setStatus('已添加图例，字体字号与当前统一字体设置一致。');
            catch ME
                uialert(app.UIFigure, ME.message, '添加图例失败');
            end
        end

        function names = legendChoiceNames(~, objects)
            names = strings(1, numel(objects));
            for k = 1:numel(objects)
                try
                    name = string(objects(k).DisplayName);
                catch
                    name = "";
                end
                if strlength(name) == 0 || startsWith(name, "_")
                    name = "data" + k;
                end
                names(k) = sprintf('%d. %s (%s)', k, name, class(objects(k)));
            end
        end

        function addTextAtPosition(app)
            ax = app.currentAxes();
            if isempty(ax) || ~isgraphics(ax)
                return
            end
            x0 = mean(ax.XLim);
            y0 = mean(ax.YLim);
            answer = inputdlg({'文本', 'x', 'y'}, '指定位置添加文本', [1 42], ...
                {'label', num2str(x0, 6), num2str(y0, 6)});
            if isempty(answer)
                return
            end
            x = str2double(answer{2});
            y = str2double(answer{3});
            if isnan(x) || isnan(y)
                uialert(app.UIFigure, 'x/y 必须是数值。', '文本位置无效');
                return
            end
            h = text(ax, x, y, answer{1}, 'FontName', app.StyleFontName, ...
                'FontSize', app.StyleFontSize, 'Interpreter', 'none', ...
                'Color', [0 0 0], 'Tag', 'gfc_text');
            app.attachObjectCallbacks(ax);
            app.refreshTree();
            app.selectGraphic(h);
            app.setStatus('已添加文本，可继续拖动或在属性表编辑。');
        end

        function addHighlight(app)
            idx = app.panelIndex(app.SelectedPanelId);
            if isempty(idx)
                return
            end
            ax = app.PanelUI(idx).Axes;
            answer = inputdlg({'x', 'y'}, '添加单点高亮', [1 30], {'0', '0'});
            if isempty(answer)
                return
            end
            x = str2double(answer{1});
            y = str2double(answer{2});
            if isnan(x) || isnan(y)
                return
            end
            gfc.addHighlight(ax, x, y);
            app.attachObjectCallbacks(ax);
            app.refreshTree();
        end

        function addScaleBar(app)
            idx = app.panelIndex(app.SelectedPanelId);
            if isempty(idx)
                return
            end
            ax = app.PanelUI(idx).Axes;
            answer = inputdlg({'长度（坐标轴单位）', '显示文字'}, '添加比例尺', [1 40], {'1', '1 unit'});
            if isempty(answer)
                return
            end
            len = str2double(answer{1});
            if isnan(len) || len <= 0
                return
            end
            gfc.addScalebar(ax, len, answer{2});
            app.attachObjectCallbacks(ax);
            app.refreshTree();
        end

        function previewFigure(app)
            fig = app.render('on');
            set(fig, 'Name', '组图预览 - 与导出使用同一渲染器');
            set(fig, 'Units', 'pixels', 'Resize', 'off');
            app.setStatus('已弹出预览窗口。预览和导出使用同一渲染器。');
        end

        function exportFigure(app)
            [file, path] = uiputfile({'*.png','PNG';'*.tif','TIF';'*.pdf','PDF';'*.svg','SVG';'*.fig','FIG'}, '导出组图');
            if isequal(file, 0)
                return
            end
            filename = fullfile(path, file);
            fig = app.render('off');
            cleanup = onCleanup(@() close(fig));
            try
                gfc.exportComposite(fig, filename, 'DPI', round(app.DPISpinner.Value));
                app.setStatus(['已导出: ' filename]);
            catch ME
                uialert(app.UIFigure, ME.message, '导出失败');
            end
        end

        function pngFile = makePreviewPng(app)
            if ~isempty(app.LastPreviewFile) && isfile(app.LastPreviewFile)
                try
                    delete(app.LastPreviewFile);
                catch
                end
            end
            pngFile = [tempname, '.png'];
            fig = app.render('off');
            cleanup = onCleanup(@() close(fig));
            gfc.exportComposite(fig, pngFile, 'DPI', round(app.DPISpinner.Value));
            app.LastPreviewFile = pngFile;
        end

        function exportDataMat(app)
            [file, path] = uiputfile({'*.mat','MAT 数据文件'}, '导出数据 MAT', 'group_figure_data.mat');
            if isequal(file, 0)
                return
            end
            groupData = gfc.extractGroupData(app.axesList(), app.Panels, app.AssetInfos, ...
                'ProjectName', 'GroupFigureComposer');
            try
                save(fullfile(path, file), 'groupData');
                app.setStatus(['已导出数据: ' fullfile(path, file)]);
            catch ME
                uialert(app.UIFigure, ME.message, '数据导出失败');
            end
        end

        function exportProject(app)
            [file, path] = uiputfile({'*.gfc.mat','GFC project (*.gfc.mat)';'*.mat','MAT file (*.mat)'}, ...
                '保存工程', 'group_figure.gfc.mat');
            if isequal(file, 0)
                return
            end
            try
                filename = fullfile(path, file);
                gfcProject = app.buildProjectState();
                save(filename, 'gfcProject', '-v7.3');
                app.setStatus(['已保存工程: ' filename]);
            catch ME
                uialert(app.UIFigure, ME.message, '工程保存失败');
            end
        end

        function importProject(app)
            [file, path] = uigetfile({'*.gfc.mat;*.mat','GFC project (*.gfc.mat, *.mat)'}, ...
                '打开工程');
            if isequal(file, 0)
                return
            end
            try
                filename = fullfile(path, file);
                data = load(filename, 'gfcProject');
                if ~isfield(data, 'gfcProject')
                    error('gfc:Project:MissingVariable', '工程文件中没有 gfcProject 变量。');
                end
                app.restoreProjectState(data.gfcProject);
                app.setStatus(['已打开工程: ' filename]);
            catch ME
                uialert(app.UIFigure, ME.message, '工程打开失败');
            end
        end

        function project = buildProjectState(app)
            app.ensureLayoutState();
            app.syncCanvasStyle(false);
            app.positionPanelUI();
            drawnow
            assets = repmat(struct('sourcePath', '', 'assetType', '', ...
                'importReport', '', 'hasContent', false, 'figBytes', uint8([])), 1, numel(app.PanelUI));
            for k = 1:numel(app.PanelUI)
                if k <= numel(app.AssetInfos)
                    assets(k).sourcePath = app.AssetInfos(k).sourcePath;
                    assets(k).assetType = app.AssetInfos(k).assetType;
                    assets(k).importReport = app.AssetInfos(k).importReport;
                end
                assets(k).hasContent = app.axesHasProjectContent(app.PanelUI(k).Axes) || ...
                    strlength(string(assets(k).sourcePath)) > 0;
                try
                    if assets(k).hasContent
                        assets(k).figBytes = app.snapshotAxesBytes(app.PanelUI(k).Axes);
                    end
                catch
                    assets(k).figBytes = uint8([]);
                end
            end
            project = struct();
            project.version = 1;
            project.savedAt = char(datetime('now'));
            project.layout = struct('rows', app.Rows, 'cols', app.Cols, ...
                'canvasWidthPx', app.CanvasWidthPx, 'canvasHeightPx', app.CanvasHeightPx, ...
                'gap', app.LayoutGap, 'margin', app.LayoutMargin, 'canvasZoom', app.CanvasZoom);
            project.style = struct('fontName', app.StyleFontName, 'fontSize', app.StyleFontSize, ...
                'palette', app.Palette, 'customMapColors', app.CustomMapColors, ...
                'customMapPositions', app.CustomMapPositions, 'customMapCount', app.CustomMapCount);
            project.panels = app.Panels;
            project.panelPositions = app.PanelPositions;
            project.axesPositions = app.AxesPositions;
            project.labelPositions = app.LabelPositions;
            project.assets = assets;
            project.selectedPanelId = app.SelectedPanelId;
        end

        function restoreProjectState(app, project)
            if ~isstruct(project) || ~isfield(project, 'layout') || ~isfield(project, 'panels')
                error('gfc:Project:InvalidProject', '不是有效的组图工程文件。');
            end
            layout = project.layout;
            app.Rows = projectValue(layout, 'rows', app.Rows);
            app.Cols = projectValue(layout, 'cols', app.Cols);
            app.CanvasWidthPx = projectValue(layout, 'canvasWidthPx', app.CanvasWidthPx);
            app.CanvasHeightPx = projectValue(layout, 'canvasHeightPx', app.CanvasHeightPx);
            app.LayoutGap = projectValue(layout, 'gap', app.LayoutGap);
            app.LayoutMargin = projectValue(layout, 'margin', app.LayoutMargin);
            app.CanvasZoom = projectValue(layout, 'canvasZoom', app.CanvasZoom);
            if isfield(project, 'style')
                app.StyleFontName = projectValue(project.style, 'fontName', app.StyleFontName);
                app.StyleFontSize = projectValue(project.style, 'fontSize', app.StyleFontSize);
                app.Palette = projectValue(project.style, 'palette', app.Palette);
                app.CustomMapColors = projectValue(project.style, 'customMapColors', app.CustomMapColors);
                app.CustomMapPositions = projectValue(project.style, 'customMapPositions', app.CustomMapPositions);
                app.CustomMapCount = projectValue(project.style, 'customMapCount', app.CustomMapCount);
            end
            app.Panels = project.panels;
            n = numel(app.Panels);
            app.AssetInfos = app.blankAssetInfos(n);
            app.PanelPositions = projectArray(project, 'panelPositions', ...
                gfc.panelPositions(app.Panels, app.Rows, app.Cols, app.LayoutGap, app.LayoutMargin), n);
            app.AxesPositions = projectArray(project, 'axesPositions', app.defaultAxesPositions(), n);
            app.LabelPositions = projectArray(project, 'labelPositions', repmat([0.015 0.915 0.18 0.065], n, 1), n);
            if ~isempty(app.RowsSpinner) && isvalid(app.RowsSpinner), app.RowsSpinner.Value = app.Rows; end
            if ~isempty(app.ColsSpinner) && isvalid(app.ColsSpinner), app.ColsSpinner.Value = app.Cols; end
            if ~isempty(app.CanvasWidthField) && isvalid(app.CanvasWidthField), app.CanvasWidthField.Value = app.CanvasWidthPx; end
            if ~isempty(app.CanvasHeightField) && isvalid(app.CanvasHeightField), app.CanvasHeightField.Value = app.CanvasHeightPx; end
            if ~isempty(app.GapField) && isvalid(app.GapField), app.GapField.Value = app.LayoutGap; end
            if ~isempty(app.MarginField) && isvalid(app.MarginField), app.MarginField.Value = app.LayoutMargin; end
            if ~isempty(app.FontDropDown) && isvalid(app.FontDropDown) && any(strcmp(app.StyleFontName, app.FontDropDown.Items))
                app.FontDropDown.Value = app.StyleFontName;
            end
            if ~isempty(app.FontSizeSpinner) && isvalid(app.FontSizeSpinner), app.FontSizeSpinner.Value = app.StyleFontSize; end
            if ~isempty(app.CustomMapCountSpinner) && isvalid(app.CustomMapCountSpinner), app.CustomMapCountSpinner.Value = app.CustomMapCount; end
            if ~isempty(app.CanvasZoomSpinner) && isvalid(app.CanvasZoomSpinner), app.CanvasZoomSpinner.Value = app.CanvasZoom; end
            app.applyFixedWindowSize();
            app.rebuildCanvas();
            if isfield(project, 'assets')
                for k = 1:min(n, numel(project.assets))
                    app.restorePanelAsset(k, project.assets(k));
                end
            end
            app.syncCanvasStyle(false);
            app.updatePaletteSwatches();
            app.updateCustomMapButtons();
            app.SelectedPanelId = projectValue(project, 'selectedPanelId', app.Panels(1).id);
            app.selectPanel(app.SelectedPanelId);
            app.positionPanelUI();
            app.refreshTree();
        end

        function restorePanelAsset(app, idx, asset)
            if isfield(asset, 'figBytes') && ~isempty(asset.figBytes)
                report = app.restoreAxesBytes(app.PanelUI(idx).Axes, asset.figBytes);
                assetType = projectValue(asset, 'assetType', 'project');
                sourcePath = projectValue(asset, 'sourcePath', '');
                importReport = report;
            elseif isfield(asset, 'sourcePath') && isfile(asset.sourcePath)
                app.importFileToPanel(idx, asset.sourcePath, false);
                return
            else
                return
            end
            app.Panels(idx).sourcePath = sourcePath;
            app.Panels(idx).assetType = assetType;
            app.Panels(idx).importReport = importReport;
            app.AssetInfos(idx) = struct('sourcePath', sourcePath, 'assetType', assetType, 'importReport', importReport);
            app.PanelUI(idx).Button.Text = '+';
            app.attachObjectCallbacks(app.PanelUI(idx).Axes);
        end

        function bytes = snapshotAxesBytes(~, ax)
            bytes = uint8([]);
            p = gfc.createPanels(1, 1);
            fig = gfc.renderCompositeFigure(p, ax, 'Rows', 1, 'Cols', 1, ...
                'Visible', 'off', 'WidthPx', 900, 'HeightPx', 650, ...
                'Positions', [0 0 1 1], 'AxesPositions', [0.12 0.12 0.78 0.78], ...
                'AxesPositionsAreAbsolute', true, 'AxesPositionsAreFrame', true);
            tmp = [tempname, '.fig'];
            cleanupFig = onCleanup(@() close(fig));
            cleanupFile = onCleanup(@() deleteIfExists(tmp));
            savefig(fig, tmp);
            fid = fopen(tmp, 'r');
            if fid < 0
                return
            end
            cleanupFid = onCleanup(@() fclose(fid));
            bytes = fread(fid, Inf, '*uint8').';
        end

        function report = restoreAxesBytes(~, ax, bytes)
            tmp = [tempname, '.fig'];
            cleanupFile = onCleanup(@() deleteIfExists(tmp));
            fid = fopen(tmp, 'w');
            if fid < 0
                error('gfc:Project:TempFile', '无法创建临时工程快照文件。');
            end
            written = fwrite(fid, bytes, 'uint8');
            fclose(fid);
            if written ~= numel(bytes)
                error('gfc:Project:TempFile', '工程快照写入不完整。');
            end
            report = gfc.importFigToAxes(ax, tmp);
            report = ['Project snapshot restored. ' report];
        end

        function fig = render(app, visible)
            app.ensureLayoutState();
            app.syncCanvasStyle(false);
            [panelPositions, axesPositions, labelPositions, canvasSize] = app.canvasRenderGeometry();
            fig = gfc.renderCompositeFigure(app.Panels, app.axesList(), ...
                'Rows', app.Rows, 'Cols', app.Cols, 'Visible', visible, ...
                'WidthPx', canvasSize(1), 'HeightPx', canvasSize(2), ...
                'Positions', panelPositions, 'AxesPositions', axesPositions, ...
                'AxesPositionsAreAbsolute', true, 'AxesPositionsAreFrame', true, ...
                'LabelPositions', labelPositions, 'LabelPositionsAreAbsolute', true, ...
                'LabelFontName', app.StyleFontName, 'LabelFontSize', app.StyleFontSize + 2);
        end

        function [panelPositions, axesPositions, labelPositions, canvasSize] = canvasRenderGeometry(app)
            app.positionPanelUI();
            drawnow
            canvasRect = app.editorCanvasRect();
            canvasSize = max(1, round([app.CanvasWidthPx app.CanvasHeightPx]));
            panelPositions = zeros(numel(app.PanelUI), 4);
            axesPositions = zeros(numel(app.PanelUI), 4);
            labelPositions = zeros(numel(app.PanelUI), 4);
            for k = 1:numel(app.PanelUI)
                panelRect = getpixelposition(app.PanelUI(k).Container, true);
                axesRect = app.axesFramePixelRect(k);
                labelRect = childRectFromPosition(panelRect, app.PanelUI(k).Label.Position);
                panelPositions(k, :) = normalizeCanvasRect(panelRect, canvasRect);
                axesPositions(k, :) = normalizeCanvasRect(axesRect, canvasRect);
                labelPositions(k, :) = normalizeCanvasRect(labelRect, canvasRect);
            end
        end

        function refreshTree(app)
            delete(app.Tree.Children);
            root = uitreenode(app.Tree, 'Text', '组图项目', 'NodeData', struct('kind', 'root'));
            for k = 1:numel(app.Panels)
                p = app.Panels(k);
                pnode = uitreenode(root, 'Text', sprintf('Panel %s  [%d,%d %dx%d]', ...
                    sprintf(p.labelFormat, p.label), p.row, p.col, p.rowSpan, p.colSpan), ...
                    'NodeData', struct('kind', 'panel', 'panelId', p.id));
                if k <= numel(app.PanelUI) && isgraphics(app.PanelUI(k).Axes)
                    ax = app.PanelUI(k).Axes;
                    anode = uitreenode(pnode, 'Text', 'Axes', ...
                        'NodeData', struct('kind', 'handle', 'handle', ax));
                    labelHandles = [ax.Title; ax.XLabel; ax.YLabel; ax.ZLabel];
                    labelNames = {'Title', 'XLabel', 'YLabel', 'ZLabel'};
                    for labelIdx = 1:numel(labelHandles)
                        if isgraphics(labelHandles(labelIdx))
                            uitreenode(anode, 'Text', labelNames{labelIdx}, ...
                                'NodeData', struct('kind', 'handle', 'handle', labelHandles(labelIdx)));
                        end
                    end
                    objs = findall(ax);
                    objs = flipud(objs(:));
                    for j = 1:numel(objs)
                        h = objs(j);
                        if h == ax || any(h == labelHandles) || isa(h, 'matlab.graphics.axis.AxesToolbar')
                            continue
                        end
                        uitreenode(anode, 'Text', objectLabel(h), ...
                            'NodeData', struct('kind', 'handle', 'handle', h));
                    end
                end
            end
            expand(root);
        end

        function treeSelectionChanged(app, event)
            node = event.SelectedNodes;
            if isempty(node)
                return
            end
            data = node.NodeData;
            if isfield(data, 'kind') && strcmp(data.kind, 'panel')
                app.selectPanel(data.panelId);
            elseif isfield(data, 'kind') && strcmp(data.kind, 'handle') && isgraphics(data.handle)
                if isa(data.handle, 'matlab.ui.control.UIAxes')
                    idx = app.axesIndex(data.handle);
                    if ~isempty(idx)
                        app.selectPanel(app.PanelUI(idx).PanelId);
                    end
                else
                    app.selectGraphic(data.handle);
                end
            end
        end

        function showPropertiesForPanel(app, idx)
            p = app.Panels(idx);
            app.PropertyTable.Data = {
                'PanelId', p.id
                'Label', p.label
                'LabelFormat', p.labelFormat
                'BorderWidth', p.borderWidth
                'InnerPadding', p.innerPadding
                'AxesPosition', mat2str(app.AxesPositions(idx, :), 4)
                'BorderColor', mat2str(p.borderColor)
                'SourcePath', p.sourcePath
                'AssetType', p.assetType
                };
        end

        function showPropertiesForHandle(app, h)
            if isa(h, 'matlab.ui.control.UIAxes')
                app.PropertyTable.Data = {
                    'Title', gfc.valueToString(h.Title.String)
                    'XLabel', gfc.valueToString(h.XLabel.String)
                    'YLabel', gfc.valueToString(h.YLabel.String)
                    'FontName', gfc.valueToString(h.FontName)
                    'FontSize', gfc.valueToString(h.FontSize)
                    'LineWidth', gfc.valueToString(h.LineWidth)
                    'Box', gfc.valueToString(h.Box)
                    'XLim', gfc.valueToString(h.XLim)
                    'YLim', gfc.valueToString(h.YLim)
                    'CLim', gfc.valueToString(h.CLim)
                    };
                return
            end
            props = editableProps(h);
            data = cell(0, 2);
            for k = 1:numel(props)
                try
                    data(end + 1, :) = {props{k}, gfc.valueToString(h.(props{k}))}; %#ok<AGROW>
                catch
                end
            end
            if isempty(data)
                data = {'Class', class(h)};
            end
            app.PropertyTable.Data = data;
        end

        function propertyEdited(app, event)
            if isempty(event.Indices) || size(app.PropertyTable.Data, 1) < event.Indices(1)
                return
            end
            prop = app.PropertyTable.Data{event.Indices(1), 1};
            newText = event.NewData;
            idx = app.panelIndex(app.SelectedPanelId);
            panelProps = {'Label','LabelFormat','BorderWidth','InnerPadding','AxesPosition','BorderColor'};
            if any(strcmp(prop, panelProps)) && ~isempty(idx)
                app.applyPanelProperty(idx, prop, newText);
                return
            end
            h = app.SelectedHandle;
            if isa(h, 'matlab.ui.control.UIAxes') && app.applyAxesPseudoProperty(h, prop, newText)
                app.showPropertiesForHandle(h);
                app.refreshTree();
                return
            end
            if isempty(h) || ~isgraphics(h) || ~isprop(h, prop)
                return
            end
            try
                oldValue = h.(prop);
                h.(prop) = gfc.stringToValue(newText, oldValue);
                app.showPropertiesForHandle(h);
                app.refreshTree();
            catch ME
                uialert(app.UIFigure, ME.message, '属性修改失败');
            end
        end

        function applyPanelProperty(app, idx, prop, newText)
            try
                switch prop
                    case 'Label'
                        app.Panels(idx).label = char(newText);
                    case 'LabelFormat'
                        app.Panels(idx).labelFormat = char(newText);
                    case 'BorderWidth'
                        app.Panels(idx).borderWidth = str2double(string(newText));
                    case 'InnerPadding'
                        app.Panels(idx).innerPadding = str2double(string(newText));
                        pad = min(max(app.Panels(idx).innerPadding, 0), 0.35);
                        app.AxesPositions(idx, :) = [pad, pad, 1 - 2*pad, 1 - 2*pad];
                    case 'AxesPosition'
                        axesPos = str2num(char(newText)); %#ok<ST2NM>
                        if numel(axesPos) ~= 4
                            error('gfc:AxesPosition:InvalidValue', 'AxesPosition must be [x y w h].');
                        end
                        app.AxesPositions(idx, :) = clampAxesPosition(axesPos(:).', 0.04);
                    case 'BorderColor'
                        app.Panels(idx).borderColor = str2num(char(newText)); %#ok<ST2NM>
                end
                app.PanelUI(idx).Label.Text = sprintf(app.Panels(idx).labelFormat, app.Panels(idx).label);
                app.positionPanelUI();
                app.LabelField.Value = app.Panels(idx).label;
                app.LabelFormatDropDown.Value = app.Panels(idx).labelFormat;
                app.showPropertiesForPanel(idx);
                app.refreshTree();
            catch ME
                uialert(app.UIFigure, ME.message, 'Panel 属性修改失败');
            end
        end

        function applied = applyAxesPseudoProperty(~, ax, prop, newText)
            applied = true;
            try
                switch prop
                    case 'Title'
                        ax.Title.String = newText;
                    case 'XLabel'
                        ax.XLabel.String = newText;
                    case 'YLabel'
                        ax.YLabel.String = newText;
                    otherwise
                        applied = false;
                end
            catch
                applied = false;
            end
        end

        function idx = panelIndex(app, panelId)
            idx = find([app.Panels.id] == panelId, 1);
        end

        function idx = axesIndex(app, ax)
            idx = [];
            for k = 1:numel(app.PanelUI)
                if isgraphics(app.PanelUI(k).Axes) && isequal(app.PanelUI(k).Axes, ax)
                    idx = k;
                    return
                end
            end
        end

        function idx = containerIndex(app, container)
            idx = [];
            if isempty(container) || ~isgraphics(container)
                return
            end
            for k = 1:numel(app.PanelUI)
                if isgraphics(app.PanelUI(k).Container) && isequal(app.PanelUI(k).Container, container)
                    idx = k;
                    return
                end
            end
        end

        function tf = isCanvasAxes(app, h)
            tf = false;
            if isempty(h) || ~isgraphics(h)
                return
            end
            for k = 1:numel(app.PanelUI)
                if isgraphics(app.PanelUI(k).Axes) && isequal(app.PanelUI(k).Axes, h)
                    tf = true;
                    return
                end
            end
        end

        function axesList = axesList(app)
            axesList = gobjects(1, numel(app.PanelUI));
            for k = 1:numel(app.PanelUI)
                axesList(k) = app.PanelUI(k).Axes;
            end
        end

        function ax = currentAxes(app)
            h = app.SelectedHandle;
            if ~isempty(h) && isgraphics(h)
                if isa(h, 'matlab.ui.control.UIAxes')
                    ax = h;
                    return
                end
                ax = ancestor(h, 'matlab.ui.control.UIAxes');
                if ~isempty(ax) && isgraphics(ax)
                    return
                end
            end
            ax = app.selectedPanelAxes();
        end

        function ax = selectedPanelAxes(app)
            ax = [];
            idx = app.panelIndex(app.SelectedPanelId);
            if ~isempty(idx) && idx <= numel(app.PanelUI) && isgraphics(app.PanelUI(idx).Axes)
                ax = app.PanelUI(idx).Axes;
            end
        end

        function climValue = parseCLimValue(app)
            climValue = [];
            textValue = strtrim(string(app.CLimField.Value));
            if strlength(textValue) == 0
                return
            end
            value = str2num(char(textValue)); %#ok<ST2NM>
            if numel(value) ~= 2 || any(~isfinite(value)) || value(1) >= value(2)
                error('gfc:CLim:InvalidValue', 'CLim 请输入 [min max]，且 min < max。');
            end
            climValue = value(:).';
        end

        function tf = axesHasMapObjects(~, ax)
            tf = false;
            if isempty(ax) || ~isgraphics(ax)
                return
            end
            candidates = [findobj(ax, 'Type', 'image'); ...
                findobj(ax, 'Type', 'surface'); ...
                findobj(ax, 'Type', 'patch')];
            for h = reshape(candidates, 1, [])
                if isprop(h, 'CData')
                    try
                        cdata = h.CData;
                        if ~isempty(cdata)
                            tf = true;
                            return
                        end
                    catch
                    end
                end
            end
        end

        function tf = axesHasProjectContent(~, ax)
            tf = false;
            if isempty(ax) || ~isgraphics(ax)
                return
            end
            try
                if ~isempty(allchild(ax))
                    tf = true;
                    return
                end
                labels = [string(ax.Title.String), string(ax.XLabel.String), string(ax.YLabel.String), string(ax.ZLabel.String)];
                tf = any(strlength(labels) > 0);
            catch
                tf = false;
            end
        end

        function infos = blankAssetInfos(~, n)
            infos = repmat(struct('sourcePath', '', 'assetType', '', 'importReport', ''), 1, n);
        end

        function setStatus(app, text)
            app.StatusLabel.Text = text;
            drawnow limitrate
        end
    end
end

function value = projectValue(s, fieldName, defaultValue)
value = defaultValue;
try
    if isstruct(s) && isfield(s, fieldName) && ~isempty(s.(fieldName))
        value = s.(fieldName);
    end
catch
end
end

function value = projectArray(s, fieldName, defaultValue, nRows)
value = defaultValue;
try
    if isstruct(s) && isfield(s, fieldName)
        candidate = s.(fieldName);
        if isnumeric(candidate) && size(candidate, 1) == nRows && size(candidate, 2) == 4
            value = candidate;
        end
    end
catch
end
end

function deleteIfExists(filename)
try
    if isfile(filename)
        delete(filename);
    end
catch
end
end

function label = objectLabel(h)
try
    dn = string(h.DisplayName);
catch
    dn = "";
end
if strlength(dn) > 0 && ~startsWith(dn, "_")
    label = sprintf('%s: %s', class(h), dn);
else
    label = class(h);
end
end

function props = editableProps(h)
base = {'Color','LineStyle','LineWidth','Marker','MarkerSize','MarkerFaceColor','MarkerEdgeColor', ...
    'FontName','FontSize','FontWeight','FontAngle','String','Position', ...
    'XLim','YLim','CLim','XScale','YScale','XDir','YDir','Box','TickDir', ...
    'XData','YData','ZData','CData','AlphaData','Visible','DisplayName'};
props = {};
for k = 1:numel(base)
    if isprop(h, base{k})
        props{end + 1} = base{k}; %#ok<AGROW>
    end
end
end

function tf = pointInRect(point, rect)
tf = point(1) >= rect(1) && point(1) <= rect(1) + rect(3) && ...
    point(2) >= rect(2) && point(2) <= rect(2) + rect(4);
end

function out = normalizeCanvasRect(rect, canvasRect)
out = [(rect(1) - canvasRect(1)) / max(canvasRect(3), 1), ...
    (rect(2) - canvasRect(2)) / max(canvasRect(4), 1), ...
    rect(3) / max(canvasRect(3), 1), rect(4) / max(canvasRect(4), 1)];
end

function rect = childRectFromPosition(parentRect, childPosition)
rect = [parentRect(1) + childPosition(1), parentRect(2) + childPosition(2), ...
    childPosition(3), childPosition(4)];
end

function pointer = dragPointer(edgeName, onLabel)
if onLabel
    pointer = 'fleur';
elseif contains(edgeName, 'left') || contains(edgeName, 'right')
    pointer = 'left';
elseif contains(edgeName, 'top') || contains(edgeName, 'bottom')
    pointer = 'top';
else
    pointer = 'arrow';
end
end

function pos = clampPanelPosition(pos, minSize)
if pos(3) < minSize
    pos(3) = minSize;
end
if pos(4) < minSize
    pos(4) = minSize;
end
if pos(1) < 0
    pos(3) = pos(3) + pos(1);
    pos(1) = 0;
end
if pos(2) < 0
    pos(4) = pos(4) + pos(2);
    pos(2) = 0;
end
if pos(1) + pos(3) > 1
    pos(3) = 1 - pos(1);
end
if pos(2) + pos(4) > 1
    pos(4) = 1 - pos(2);
end
pos(3) = max(pos(3), minSize);
pos(4) = max(pos(4), minSize);
end

function pos = clampAxesPosition(pos, minSize)
if pos(3) < minSize
    pos(3) = minSize;
end
if pos(4) < minSize
    pos(4) = minSize;
end
if pos(1) < 0
    pos(3) = pos(3) + pos(1);
    pos(1) = 0;
end
if pos(2) < 0
    pos(4) = pos(4) + pos(2);
    pos(2) = 0;
end
if pos(1) + pos(3) > 1
    pos(3) = 1 - pos(1);
end
if pos(2) + pos(4) > 1
    pos(4) = 1 - pos(2);
end
pos(3) = max(pos(3), minSize);
pos(4) = max(pos(4), minSize);
end

function point = axesDataPoint(ax)
try
    cp = ax.CurrentPoint;
    point = cp(1, 1:2);
catch
    point = [0 0];
end
end

function bounds = graphicBoundsFromPosition(h, newPosition)
currentBounds = graphicBounds(h);
bounds = currentBounds;
try
    oldPosition = h.Position;
    bounds(1) = currentBounds(1) + newPosition(1) - oldPosition(1);
    bounds(2) = currentBounds(2) + newPosition(2) - oldPosition(2);
    if numel(newPosition) >= 4 && isa(h, 'matlab.graphics.primitive.Rectangle')
        bounds = newPosition(1:4);
    end
catch
    if numel(newPosition) >= 4
        bounds = newPosition(1:4);
    elseif numel(newPosition) >= 2
        bounds = [newPosition(1), newPosition(2), 0, 0];
    end
end
end

function bounds = graphicBounds(h)
bounds = [NaN NaN NaN NaN];
try
    if isa(h, 'matlab.graphics.primitive.Rectangle')
        bounds = h.Position;
        return
    end
catch
end
try
    if isa(h, 'matlab.graphics.chart.primitive.Line')
        x = h.XData;
        y = h.YData;
        bounds = [min(x), min(y), max(x) - min(x), max(y) - min(y)];
        return
    end
catch
end
try
    if isa(h, 'matlab.graphics.primitive.Text')
        ext = h.Extent;
        if numel(ext) >= 4 && all(isfinite(ext(1:4)))
            bounds = ext(1:4);
        else
            pos = h.Position;
            bounds = [pos(1), pos(2), 0, 0];
        end
    end
catch
end
end

function label = graphicSnapLabel(h)
label = class(h);
try
    if isa(h, 'matlab.graphics.primitive.Text') && strlength(string(h.String)) > 0
        label = "文字 " + join(string(h.String), " ");
    elseif isa(h, 'matlab.graphics.primitive.Rectangle')
        label = "矩形框";
    elseif isa(h, 'matlab.graphics.chart.primitive.Line')
        label = string(h.DisplayName);
        if strlength(label) == 0
            label = "线";
        end
    end
catch
    label = class(h);
end
end

function rect = axesFramePixelRectForAxes(ax)
rect = getpixelposition(ax, true);
try
    oldUnits = ax.Units;
    ax.Units = 'pixels';
    restoreUnits = onCleanup(@() set(ax, 'Units', oldUnits));
    innerPos = ax.InnerPosition;
    if numel(innerPos) ~= 4 || any(~isfinite(innerPos)) || any(innerPos(3:4) <= 0)
        return
    end
    parentRect = getpixelposition(ax.Parent, true);
    rect = [parentRect(1) + innerPos(1), parentRect(2) + innerPos(2), ...
        innerPos(3), innerPos(4)];
    clear restoreUnits
catch
end
end

function [nearLeft, nearRight, nearBottom, nearTop] = edgeFlags(point, rect, threshold)
nearLeft = abs(point(1) - rect(1)) <= threshold;
nearRight = abs(point(1) - (rect(1) + rect(3))) <= threshold;
nearBottom = abs(point(2) - rect(2)) <= threshold;
nearTop = abs(point(2) - (rect(2) + rect(4))) <= threshold;
end

function guide = emptyGuide()
guide = struct('x', NaN, 'y', NaN, 'texts', strings(0));
end

function refs = panelXRefs(rects)
refs = refStruct(numel(rects(:, 1)) * 3);
idx = 0;
for k = 1:size(rects, 1)
    values = [rects(k, 1), rects(k, 1) + rects(k, 3)/2, rects(k, 1) + rects(k, 3)];
    names = {'左边缘','水平中心','右边缘'};
    for n = 1:3
        idx = idx + 1;
        refs(idx).value = values(n);
        refs(idx).owner = k;
        refs(idx).edge = names{n};
    end
end
end

function refs = panelYRefs(rects)
refs = refStruct(numel(rects(:, 1)) * 3);
idx = 0;
for k = 1:size(rects, 1)
    values = [rects(k, 2), rects(k, 2) + rects(k, 4)/2, rects(k, 2) + rects(k, 4)];
    names = {'下边缘','垂直中心','上边缘'};
    for n = 1:3
        idx = idx + 1;
        refs(idx).value = values(n);
        refs(idx).owner = k;
        refs(idx).edge = names{n};
    end
end
end

function refs = axesFrameXRefs(rects)
refs = refStruct(numel(rects(:, 1)) * 3);
idx = 0;
for k = 1:size(rects, 1)
    values = [rects(k, 1), rects(k, 1) + rects(k, 3)/2, rects(k, 1) + rects(k, 3)];
    names = {'plot left frame','plot horizontal center','plot right frame'};
    for n = 1:3
        idx = idx + 1;
        refs(idx).value = values(n);
        refs(idx).owner = k;
        refs(idx).edge = names{n};
    end
end
end

function refs = axesFrameYRefs(rects)
refs = refStruct(numel(rects(:, 1)) * 3);
idx = 0;
for k = 1:size(rects, 1)
    values = [rects(k, 2), rects(k, 2) + rects(k, 4)/2, rects(k, 2) + rects(k, 4)];
    names = {'plot bottom frame','plot vertical center','plot top frame'};
    for n = 1:3
        idx = idx + 1;
        refs(idx).value = values(n);
        refs(idx).owner = k;
        refs(idx).edge = names{n};
    end
end
end

function refs = rectXRefs(rects)
refs = panelXRefs([rects(:, 1), rects(:, 2), rects(:, 3), rects(:, 4)]);
end

function refs = rectYRefs(rects)
refs = panelYRefs([rects(:, 1), rects(:, 2), rects(:, 3), rects(:, 4)]);
end

function refs = graphicXRefs(bounds)
refs = panelXRefs(bounds);
end

function refs = graphicYRefs(bounds)
refs = panelYRefs(bounds);
end

function refs = refStruct(n)
refs = repmat(struct('value', NaN, 'owner', 1, 'edge', ''), max(n, 0), 1);
end

function [snap, desc] = nearestSnap(movingValues, refs, tolerance, labels, movingNames, offsets)
snap = [];
desc = "";
if isempty(refs) || isempty(movingValues)
    return
end
if isscalar(offsets)
    offsets = repmat(offsets, size(movingValues));
end
bestDistance = Inf;
bestMoving = 1;
bestRef = 1;
for m = 1:numel(movingValues)
    for r = 1:numel(refs)
        d = abs(movingValues(m) - refs(r).value);
        if d < bestDistance
            bestDistance = d;
            bestMoving = m;
            bestRef = r;
        end
    end
end
if bestDistance <= tolerance
    snap = struct('refValue', refs(bestRef).value, ...
        'newStart', refs(bestRef).value - offsets(bestMoving));
    movingName = string(movingNames{min(bestMoving, numel(movingNames))});
    ownerName = labels(refs(bestRef).owner);
    desc = movingName + " 对齐 " + ownerName + " " + string(refs(bestRef).edge);
end
end
