function cells = panelCells(panel)
%PANELCELLS Return [row col] cells covered by one panel spec.

[rr, cc] = ndgrid(panel.row:(panel.row + panel.rowSpan - 1), ...
                  panel.col:(panel.col + panel.colSpan - 1));
cells = [rr(:), cc(:)];
end
