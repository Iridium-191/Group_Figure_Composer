# 组图工具 Group Figure Composer

这是一个用于科研论文多 panel 组图的 MATLAB 工具。它可以把 MATLAB `.fig`、SVG 和常见位图图片导入到固定像素尺寸的画布中，进行 panel 合并、字体统一、颜色调整、标注、比例尺、预览和多格式导出。

默认启动入口：

```matlab
addpath(genpath(pwd))
GroupFigureComposer
```

命令行轻量入口：

```matlab
addpath(genpath(pwd))

files = ["panel_a.fig", "panel_b.svg", "panel_c.png"];
GroupFigureComposerLite(files, 'composite.png', ...
    Rows=1, Cols=3, WidthPx=1800, HeightPx=650, DPI=300);
```

运行示例：

```matlab
run("examples/demo_lite.m")
```

## 适合解决的问题

这个工具主要面向论文投稿前的组图阶段。典型需求包括：把几个 MATLAB 图、模拟结果图、显微图或 SVG 图组合到同一张固定尺寸画布中，统一字号和线宽，给 panel 加 a/b/c 编号，添加比例尺和局部高亮，并导出 PNG、TIF、PDF、SVG 或 FIG。

## 已实现能力

- 新建固定像素尺寸画布，不再混用横纵比和 cm 宽度，避免尺寸参数冲突。
- 支持行列布局、矩形 panel 合并和取消合并。
- App 窗口按画布尺寸锁定，避免误 resize 改变最终排版。
- Panel 间距和页面边距可调，修改后同步画布、预览和导出。
- 可拖动 panel 边框做局部尺寸微调，也可拖动 panel 空白/title 区域移动整个 panel。
- 每个 panel 有独立 axes 位置状态，可拖动 axes 空白区域移动坐标区，也可拖动 axes 边框/角点调整比例和尺寸。
- 每个 panel 默认编号为 `a, b, c... aa...`，编号文字、格式和位置都可改。
- 标题、坐标轴标签、普通文本、矩形框、比例尺线和比例尺文字可以在画布上直接拖动。
- 磁吸开启时，拖动 panel、axes、panel 编号或图元会显示参考线，便于对齐。
- 图元磁吸会跨所有 panel 比较文字、矩形框和比例尺线的边界与中心。
- Panel 外框只作为编辑辅助容器，最终预览和导出图不会保留这些外框。
- 每个 panel 有 `+` 导入按钮，支持 `.fig`、`.svg`、`.png`、`.jpg`、`.jpeg`、`.tif`、`.tiff`、`.bmp`。
- 位图支持自动裁白边。
- SVG 会优先解析常见图元；复杂 SVG 在安装 Inkscape 后可栅格化兜底。
- FIG 导入会复制主要坐标轴图元，并尽量保留常用坐标轴样式、legend 和 colorbar。
- 支持统一字体、字号、线宽、坐标轴框线。
- 右侧树状对象列表和属性表可编辑常用图元属性。
- 支持 Delete/Backspace 或“删除选中元素”按钮删除冗余图元。
- 内置 `Okabe-Ito`、`Nature Muted`、`Science Bright`、`Tableau 10`、`ColorBrewer`、`Viridis/Cividis/Magma/Inferno/Plasma` 等色卡。
- 可导入色卡图片并提取代表颜色。
- 色卡以 swatch 按钮显示，选中谱线、散点、文字、矩形框或比例尺后点击色块即可改色。
- “所有谱线”可按当前色卡顺序重配全部 line 对象。
- `Map Colormap` 支持对当前 axes 或 panel 应用 colormap、反转 colormap，并可输入 `CLim`。
- 支持添加单点高亮和 map 比例尺。
- 预览会单独弹出固定尺寸窗口，并与导出图像使用同一个渲染器。
- 导出 `.fig`、`.svg`、`.png`、`.tif/.tiff`、`.pdf`。
- 可导出 `groupData` 到 `.mat`，例如 `fig1.curveA.x` 或 `fig1.legend_001.x`。
- 可保存和打开 `.gfc.mat` 工程文件，便于后续继续编辑。

## 环境要求

推荐环境：

- MATLAB R2024b 或更新版本。
- Inkscape 为可选依赖，只在复杂 SVG 兜底栅格化时使用。

功能相关说明：

- 位图导入依赖 MATLAB 图像读写能力。
- 从图片提取色卡时使用 `kmeans`，部分 MATLAB 安装可能需要 Statistics and Machine Learning Toolbox。
- 交互界面使用 `uifigure` 等 MATLAB UI 组件。

## `.mlapp` 说明

MATLAB 没有稳定的公开 API 可以从脚本直接生成 App Designer `.mlapp` 文件。本项目因此没有伪造一个可能打不开的 `.mlapp`。

如果必须要一个原生 `.mlapp` 包装：

1. 在 MATLAB 中打开 App Designer，新建空白 App。
2. 在 StartupFcn 中调用：

   ```matlab
   GroupFigureComposer_appdesigner_import
   ```

3. 保存为 `GroupFigureComposer.mlapp`。

这层 `.mlapp` 只作为启动壳，实际功能仍由 `GroupFigureComposerApp.m` 和 `+gfc` 包提供。

## 测试

从仓库根目录运行：

```matlab
addpath(genpath(pwd))
results = runtests("tests");
assertSuccess(results)
```

已覆盖默认编号、panel 合并/拆分、位图裁白边、MAT 数据提取、渲染几何、字体传播和基础导出。

## 作者

Ruilin Mao，ICQM, Peking University。

## 许可证

本项目使用 MIT License。见 [LICENSE](LICENSE)。
