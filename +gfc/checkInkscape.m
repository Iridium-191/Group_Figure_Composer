function exe = checkInkscape()
%CHECKINKSCAPE Return an Inkscape executable path if available.

exe = '';
candidates = { ...
    'inkscape', ...
    fullfile(getenv('ProgramFiles'), 'Inkscape', 'bin', 'inkscape.exe'), ...
    fullfile(getenv('ProgramFiles'), 'Inkscape', 'inkscape.exe'), ...
    fullfile(getenv('ProgramFiles(x86)'), 'Inkscape', 'inkscape.exe')};

for k = 1:numel(candidates)
    candidate = candidates{k};
    if isempty(candidate)
        continue
    end
    if isfile(candidate)
        exe = candidate;
        return
    end
    [status, ~] = system(sprintf('"%s" --version', candidate));
    if status == 0
        exe = candidate;
        return
    end
end
end
