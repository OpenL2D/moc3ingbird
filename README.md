# MOC3ingbird DoS

日本語版：[README_JA.md](README_JA.md)

This repository contains a simple Live2D model that crashes any application
that attempts to load it: a denial of service attack. If you have the
ImHex hex editor installed, you can inspect and edit the MOC3 file with
the pattern file in `src/moc3_v2.hexpat`.

The included files can also be used as a template for further research and
experimentation.

## Rationale and Quick Overview

These files are released in the hope that they will prompt Live2D to improve
their security practices.

There is only one widespread MOC3 reader implementation: Live2D Cubism Core.
Cubism Core is a C library that makes no attempts to perform bounds checking
on offsets contained within MOC3 files. As a result, it is trivial to read
and write memory out of the bounds of the MOC3 data in memory, and it is
almost certainly possible to execute arbitrary code this way.

## License

Copyright © 2023 The OpenL2D Project Developers. All rights reserved.

This model and all related files are free software licensed under the terms of
the Free Development Public License 1.0-US as published by the Freedom of
Development Project at <https://freedevproject.org/fdpl-1.0-us>. Usage of the
files in this repository constitutes acceptance of this license.

No file in this repository was derived from the output of any Live2D software.
All rights reserved only to the OpenL2D Project Developers, who, regarding the
distribution of these files, have no obligations to any party under any
agreement.

**To be more explicit: you are free to use the included model files and pattern
files to create your own MOC3 readers and writers. No license will restrict
your right to do so.**
