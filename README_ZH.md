# 组图工具 Group Figure Composer

用于科研论文组图的 MATLAB 工具，支持把 MATLAB `.fig`、SVG 和常见位图素材组合成一个多 panel 图，并导出图片、矢量图、MAT 数据和可继续修改的工程文件。

作者：**Ruilin Mao**，**ICQM, Peking University**

许可证：**MIT License**

## 简介

本仓库包含两个使用入口：

- **中文版交互 GUI**：适合精修论文组图、手动调整 panel、图元、字体、色卡、图例和导出。
- **英文命令式轻量工具**：适合 GitHub 发布、脚本化批量组合图像。

核心逻辑放在 `+gfc` 包中，便于测试、复用和后续扩展。界面采用固定像素画布，预览和导出使用同一套渲染路径，尽量保证画布、预览和最终导出结果一致。

## 安装

下载或克隆仓库后，在 MATLAB 当前目录运行：

```matlab
addpath(genpath(pwd))
```

推荐 MATLAB R2024b 或更新版本。

Inkscape 是可选依赖，只在复杂 SVG 无法直接解析时作为栅格化兜底使用。

## 启动方式

### 中文交互 GUI

```matlab
GroupFigureComposer
```

或者显式使用中文版入口：

```matlab
GroupFigureComposerCN
```

### 英文命令式工具

```matlab
files = ["panel_a.fig", "panel_b.svg", "panel_c.png"];
GroupFigureComposerEN(files, "composite.png", ...
    Rows=1, Cols=3, WidthPx=1800, HeightPx=650, DPI=300);
```

也可以直接调用底层轻量工具：

```matlab
GroupFigureComposerLite(files, "composite.png", ...
    Rows=1, Cols=3, WidthPx=1800, HeightPx=650, DPI=300);
```

运行示例：

```matlab
run("examples/demo_lite.m")
```

## 支持的导入格式

- MATLAB 图：`.fig`
- SVG：`.svg`
- 位图：`.png`、`.jpg`、`.jpeg`、`.tif`、`.tiff`、`.bmp`

位图导入时支持自动裁白边。SVG 会优先解析常见图元，复杂 SVG 在安装 Inkscape 后可以栅格化兜底。

## 支持的导出格式

- `.fig`
- `.svg`
- `.png`
- `.tif` / `.tiff`
- `.pdf`
- `.mat` 数据文件
- 工程文件，用于后续继续修改

## 交互 GUI 使用流程

### 1. 布局

- 输入画布宽度和高度，单位为像素。
- 设置行列数。
- 合并或取消合并矩形 panel 区域。
- 调整 panel 间距和页面边距。
- 在画布上拖动 panel，或拖动 panel 边缘调整大小。
- 每个 panel 默认生成 `a, b, c... aa...` 编号，可修改文本和格式。

### 2. 导入

- 每个空 panel 中央有 `+` 按钮，可直接导入素材。
- 也可以先选中 panel，再点击导入按钮。
- `.fig` 会复制主要 axes、图元、常见坐标轴样式、legend、colorbar、colormap 等。
- 位图会自动裁白边并自适应 panel。
- 可一键统一字体、字号、坐标轴框线、tick 方向。
- 可使用“自动对齐绘图区框线”，让相邻行/列以及最外圈绘图区框线对齐；合并后的 mapping 大图也会按底层网格边界参与对齐。

### 3. 精修

- 可点击画布图元或右侧树状对象列表选择对象。
- 右侧属性表支持编辑常用属性。
- 支持拖动 panel 编号、axes 绘图区、标题、坐标轴标签、普通文字、矩形框、比例尺文字等。
- 支持磁吸参考线，对齐 panel、axes 绘图区框线、文字、标注和图元边界。
- 可导入色卡图片，也可使用内置科研色卡。
- 色卡以 swatch 按钮显示，选中图元后点击色块即可改色，不需要手写 RGB。
- 支持对所有谱线按色卡顺序重新配色。
- 支持自定义控制点 colormap：可设置多个颜色、色轴位置和插值颜色数。
- map/image/surface 类 axes 可修改 colormap、反转 colormap 和 `CLim`。
- 可自定义 legend 展示哪些对象，legend 字体字号与统一字体设置一致。
- 可在指定数据坐标位置添加文本。
- 可添加单点高亮、矩形/圆形标注和比例尺。

### 4. 预览与导出

- 预览会单独弹出固定尺寸窗口。
- 预览和导出读取当前画布控件的真实像素位置，尽量保证 panel 间距、axes 外框、panel 编号、字体字号和 legend 内容一致。
- 可选择 DPI 导出 PNG/TIF/PDF 等。
- 可导出 `.fig` 和 `.svg`。
- 可保存工程文件，之后重新打开继续修改。

## 数据导出

导出的 `.mat` 文件中包含结构体 `groupData`。可提取的图元数据会按 panel/figure 分组，例如：

```matlab
groupData.fig1.curveA.x
groupData.fig1.curveA.y
groupData.fig1.legend_001.name
groupData.fig1.legend_001.panelLabel
```

同时会保存：

- `groupData.panelMap`
- panel 编号和位置
- 源文件路径
- 图例名到字段名的映射
- 导入报告
- 无法完整提取对象的类型和来源信息

## 仓库结构

```text
GroupFigureComposer.m          主入口，打开中文版交互 GUI
GroupFigureComposerCN.m        显式中文版 GUI 入口
GroupFigureComposerEN.m        英文命令式入口
GroupFigureComposerLite.m      英文轻量组图工具
GroupFigureComposerApp.m       主要交互 App 实现
+gfc/                         核心函数包
examples/                     示例
tests/                        MATLAB 单元测试
README.md                     双语首页
README_EN.md                  英文说明
README_ZH.md                  中文说明
LICENSE                       MIT 许可证
```

## 测试

```matlab
addpath(genpath(pwd))
results = runtests("tests");
assertSuccess(results)
```

测试覆盖 panel 布局、合并、位图裁白边、SVG 导入、legend 保留、字体统一、colormap、合并 panel 下的框线对齐、数据导出和基础渲染导出。

## 关于 `.mlapp`

当前版本采用可版本控制的 `.m` 文件实现 `uifigure` 交互 App，而不是二进制 `.mlapp`。MATLAB 没有稳定公开 API 可以从脚本可靠生成完整 `.mlapp`，因此 `.m` 文件更适合 GitHub 发布、测试和协作。

## 作者与引用

如果本工具对你的科研组图流程有帮助，可注明：

**Ruilin Mao, ICQM, Peking University. Group Figure Composer. MIT License.**
