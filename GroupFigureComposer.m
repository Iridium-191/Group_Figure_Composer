function app = GroupFigureComposer()
%GROUPFIGURECOMPOSER Launch the Chinese interactive group-figure composer.
%
% Chinese interactive GUI:
%   GroupFigureComposer
%   GroupFigureComposerCN
%
% English command-style utility:
%   GroupFigureComposerEN(files, outputFile, Name=Value)
%
% English interactive GUI:
%   GroupFigureComposerGUI_EN

app = GroupFigureComposerApp();
if nargout == 0
    clear app
end
end
