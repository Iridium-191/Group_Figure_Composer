# 使用说明

## 交互式使用

从仓库根目录或任意 MATLAB 当前路径运行：

```matlab
addpath(genpath(pwd))
GroupFigureComposer
```

推荐工作流：

1. 在“布局”页设置行列数、画布宽高、panel 间距和页面边距。
2. 如有大图区域，设置起始行/列和跨行/跨列后合并 panel。
3. 在空 panel 的 `+` 按钮处导入素材，或用“导入到选中 panel”。
4. 在“导入”页统一字体、字号、坐标轴框线和线宽。
5. 在“精修”页调整 panel 编号、颜色、图例、线型、map colormap、高亮点和比例尺。
6. 在画布中直接拖动 panel、axes、编号、文字和标注对象完成排版。
7. 在“预览导出”页弹出预览窗口。
8. 导出最终图片，或保存 `.gfc.mat` 工程文件。

## 布局逻辑

本工具使用固定像素画布。这样做的好处是预览和导出的几何位置更可控，不会因为窗口尺寸变化而意外改变排版。

编辑时看到的 panel 外框只是辅助框，最终导出不会保留这些框。

## 导入格式

支持：

- MATLAB `.fig`；
- SVG `.svg`；
- 位图 `.png`、`.jpg`、`.jpeg`、`.tif`、`.tiff`、`.bmp`。

`.fig` 导入会复制常见 axes 子对象和坐标轴样式。SVG 导入支持常见矢量图元。复杂 SVG 如果包含 mask、filter、clip path、嵌入图片、渐变等元素，可能需要安装 Inkscape 作为兜底栅格化工具。

## 直接拖动编辑

支持直接拖动：

- panel 位置和边界；
- axes 坐标区位置和边界；
- panel 编号；
- title、xlabel、ylabel、普通 text；
- 矩形框；
- 比例尺线和比例尺文字。

普通曲线默认不作为拖动对象，避免误改数据。

## 颜色和风格

内置常用论文色卡和科学 colormap。可以对所有谱线统一重配色，也可以选中某个对象后点击色块单独改色。

Map 类图像可以设置 colormap、反转 colormap，并手动输入 `CLim`。自定义 colormap 支持三个控制点颜色和控制点位置。

## 导出

支持导出：

- `.png`
- `.tif` / `.tiff`
- `.pdf`
- `.svg`
- `.fig`

预览窗口与导出使用同一渲染流程，所以预览结果应当与导出几何一致。

## 导出数据

“导出数据 MAT”会生成变量 `groupData`。典型字段形式如下：

```matlab
groupData.fig1.curveA.x
groupData.fig1.curveA.y
groupData.fig1.legend_001.name
```

字段名会尽量来自曲线的 `DisplayName`，如果名字不适合作为 MATLAB 字段名，会自动转成安全字段名。

## 保存工程

“保存工程”会生成 `.gfc.mat` 文件，保存 layout、panel 位置、axes 位置、编号位置、样式参数和导入内容快照。之后可用“打开工程”继续编辑。

## 命令行轻量用法

```matlab
addpath(genpath(pwd))

files = ["panel_a.fig", "panel_b.fig", "panel_c.png"];
result = GroupFigureComposerLite(files, 'composite.pdf', ...
    Rows=1, Cols=3, ...
    WidthPx=1800, HeightPx=650, ...
    DPI=300, ...
    FontName='Arial', FontSize=9, ...
    Visible='off');
```

常用参数：

| 参数 | 含义 | 默认值 |
|---|---|---|
| `Rows` | panel 行数 | 自动 |
| `Cols` | panel 列数 | 自动 |
| `WidthPx` | 输出画布宽度，单位 px | `1200` |
| `HeightPx` | 输出画布高度，单位 px | `900` |
| `DPI` | 导出分辨率 | `300` |
| `FontName` | 统一字体 | `Arial` |
| `FontSize` | 统一字号 | `9` |
| `Visible` | 是否显示输出 figure | `off` |

如果 `outputFile` 传空字符串，函数会返回渲染后的 figure，不直接导出。
