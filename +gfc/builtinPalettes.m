function palette = builtinPalettes(name, n)
%BUILTINPALETTES Return built-in RGB palettes and colormaps.

arguments
    name (1,:) char = 'Okabe-Ito'
    n (1,1) double {mustBeInteger,mustBePositive} = 8
end

key = lower(regexprep(name, '[\s_\-]+', ''));
isContinuous = false;
switch key
    case 'okabeito'
        base = [ ...
            0.000 0.000 0.000
            0.902 0.624 0.000
            0.337 0.706 0.914
            0.000 0.620 0.451
            0.941 0.894 0.259
            0.000 0.447 0.698
            0.835 0.369 0.000
            0.800 0.475 0.655];
    case 'naturemuted'
        base = [ ...
            0.231 0.404 0.545
            0.741 0.384 0.310
            0.353 0.561 0.431
            0.514 0.439 0.651
            0.816 0.620 0.349
            0.310 0.596 0.647
            0.573 0.361 0.302
            0.447 0.447 0.447];
    case 'sciencebright'
        base = [ ...
            0.000 0.275 0.671
            0.863 0.078 0.235
            0.000 0.620 0.380
            0.945 0.608 0.000
            0.494 0.184 0.556
            0.000 0.690 0.941
            0.902 0.486 0.133
            0.200 0.200 0.200];
    case 'tableau10'
        base = [ ...
            0.122 0.467 0.706
            1.000 0.498 0.055
            0.173 0.627 0.173
            0.839 0.153 0.157
            0.580 0.404 0.741
            0.549 0.337 0.294
            0.890 0.467 0.761
            0.498 0.498 0.498
            0.737 0.741 0.133
            0.090 0.745 0.812];
    case 'colorbrewerset2'
        base = [ ...
            0.400 0.761 0.647
            0.988 0.553 0.384
            0.553 0.627 0.796
            0.906 0.541 0.765
            0.651 0.847 0.329
            1.000 0.851 0.184
            0.898 0.769 0.580
            0.702 0.702 0.702];
    case 'colorbrewerdark2'
        base = [ ...
            0.106 0.620 0.467
            0.851 0.373 0.008
            0.459 0.439 0.702
            0.906 0.161 0.541
            0.400 0.651 0.118
            0.902 0.671 0.008
            0.651 0.463 0.114
            0.400 0.400 0.400];
    case 'gray'
        base = gray(n);
        isContinuous = true;
    case 'parula'
        base = parula(n);
        isContinuous = true;
    case 'jet'
        base = jet(n);
        isContinuous = true;
    case 'turbo'
        base = turbo(n);
        isContinuous = true;
    case 'viridis'
        base = [ ...
            0.267 0.005 0.329
            0.283 0.141 0.458
            0.254 0.265 0.530
            0.207 0.372 0.553
            0.164 0.471 0.558
            0.128 0.567 0.551
            0.135 0.659 0.518
            0.267 0.749 0.441
            0.478 0.821 0.318
            0.741 0.873 0.150
            0.993 0.906 0.144];
        isContinuous = true;
    case 'cividis'
        base = [ ...
            0.000 0.135 0.305
            0.129 0.211 0.404
            0.227 0.286 0.459
            0.329 0.365 0.477
            0.431 0.443 0.470
            0.537 0.522 0.448
            0.651 0.606 0.395
            0.773 0.698 0.285
            0.904 0.803 0.129
            0.996 0.909 0.218];
        isContinuous = true;
    case 'magma'
        base = [ ...
            0.001 0.000 0.014
            0.092 0.045 0.235
            0.251 0.063 0.416
            0.439 0.122 0.506
            0.638 0.190 0.490
            0.828 0.310 0.431
            0.955 0.533 0.285
            0.994 0.762 0.431
            0.987 0.991 0.749];
        isContinuous = true;
    case 'inferno'
        base = [ ...
            0.001 0.000 0.014
            0.087 0.044 0.224
            0.258 0.039 0.408
            0.416 0.090 0.433
            0.578 0.148 0.404
            0.749 0.244 0.318
            0.902 0.408 0.188
            0.988 0.645 0.039
            0.988 0.998 0.645];
        isContinuous = true;
    case 'plasma'
        base = [ ...
            0.050 0.030 0.528
            0.254 0.014 0.615
            0.417 0.001 0.658
            0.562 0.051 0.642
            0.693 0.165 0.565
            0.798 0.280 0.470
            0.881 0.392 0.383
            0.949 0.522 0.296
            0.988 0.690 0.205
            0.940 0.975 0.131];
        isContinuous = true;
    case 'coolwarm'
        base = [ ...
            0.230 0.299 0.754
            0.356 0.479 0.895
            0.554 0.690 0.996
            0.754 0.830 0.961
            0.865 0.865 0.865
            0.957 0.767 0.675
            0.918 0.518 0.400
            0.706 0.016 0.150];
        isContinuous = true;
    otherwise
        error('gfc:builtinPalettes:UnknownPalette', 'Unknown palette: %s', name);
end

if isContinuous
    palette = interpolatePalette(base, n);
else
    repeats = ceil(n / size(base, 1));
    palette = repmat(base, repeats, 1);
    palette = palette(1:n, :);
end
palette = min(max(palette, 0), 1);
end

function palette = interpolatePalette(base, n)
if size(base, 1) == n
    palette = base;
    return
end
x = linspace(0, 1, size(base, 1));
xq = linspace(0, 1, n);
palette = interp1(x, base, xq, 'linear');
end
