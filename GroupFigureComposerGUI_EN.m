function app = GroupFigureComposerGUI_EN()
%GROUPFIGURECOMPOSERGUI_EN Launch the English interactive GUI.
%
% The English GUI shares the same editing engine as the Chinese GUI and
% translates the visible interface shell after startup.
%
% Chinese GUI:
%   GroupFigureComposerCN
%
% English command-style utility:
%   GroupFigureComposerEN(files, outputFile, Name=Value)

app = GroupFigureComposerApp();
gfc.applyEnglishUi(app, true);
if nargout == 0
    clear app
end
end
