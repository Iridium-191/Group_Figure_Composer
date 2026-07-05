function GroupFigureComposer_appdesigner_import()
%GROUPFIGURECOMPOSER_APPDESIGNER_IMPORT
% App Designer wrapper entry point.
%
% MATLAB does not provide a stable public API for generating .mlapp files
% from scripts. Create a blank App Designer app if you need a native .mlapp,
% then call this function from StartupFcn to use the implemented tool.

GroupFigureComposer();
end
