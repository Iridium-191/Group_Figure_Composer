# Security Policy

Group Figure Composer is a local MATLAB tool. It does not intentionally collect data, open network connections, or upload user files.

## Reporting a vulnerability

Please open a private security advisory on GitHub if the repository enables it. If not, contact the maintainer through the repository owner profile.

Include:

- affected version or commit;
- operating system and MATLAB version;
- steps to reproduce;
- the expected impact;
- any suggested mitigation.

## File-handling note

This tool reads local `.fig`, `.svg`, and raster files selected by the user. Treat files from unknown sources with normal caution. Complex SVG files may be passed to Inkscape if fallback rendering is enabled and Inkscape is installed.
