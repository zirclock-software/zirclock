<p align="center">
  <img src="docs/logo.png" alt="ZirClock logo" height="140">
</p>

<h1 align="center">ZirClock</h1>

<p align="center">
  <strong>A desktop application for zircon petrochronology</strong><br>
  from raw analyses to publication-ready diagrams in a single, reproducible workflow.
</p>

<p align="center">
  <a href="LICENSE"><img alt="License: GPL v3+" src="https://img.shields.io/badge/license-GPL--3.0--or--later-blue"></a>
  <img alt="Platforms" src="https://img.shields.io/badge/platform-Windows%20%7C%20macOS-lightgrey">
</p>

ZirClock brings U–Pb geochronology, Lu–Hf isotope evolution, Ti-in-zircon
thermometry and trace-element / REE geochemistry together in one place, so a
zircon dataset can be reduced, filtered, interpreted and plotted without moving
between spreadsheets, statistical packages and drawing programs.

> **Status: v3.0.** ZirClock is research software in active development. If
> you find a bug or something behaves unexpectedly, please
> [open an issue](../../issues).
>
> **Formerly Chronikon (2.x) and Zirchron (1.x).** Same program, new name.
> Project files saved by either keep opening — `.chronikon` and `.zirchron`
> are read for good — and installing 3.0 on Windows replaces the previous
> version in place.

---

## Download and install

Go to the [**Releases**](../../releases) page and download the file for your
system:

| System | Download |
|---|---|
| **Windows** 10 / 11 (64-bit) | `ZirClock-3.0-windows-setup.exe` |
| **macOS** 14+, Apple Silicon | `ZirClock-3.0-arm64.dmg` |
| **macOS** 13+, Intel | `ZirClock-3.0-intel.dmg` |

Step-by-step instructions for both systems, including the one-time security
prompts and troubleshooting, are in [INSTALL.md](INSTALL.md).

In short:

- **Windows** — run the installer. Windows shows a blue *"Windows protected
  your PC"* screen because the program is not signed with a paid certificate:
  click **More info → Run anyway**. It installs into your user folder without
  an administrator password.
- **macOS** — open the `.dmg` and drag ZirClock to Applications. The first
  time, macOS blocks it because it is not notarized: go to **System Settings →
  Privacy & Security → Open Anyway**. Only once.

---

## What ZirClock does

**U–Pb geochronology**
Wetherill and Tera–Wasserburg concordia, York discordia (Models 1–3 with full
error propagation), concordia ages and P(concordance) (Ludwig 1998), weighted
means with MSWD / P(MSWD), and configurable discordance, precision and outlier
filters. Best-age selection follows the Spencer et al. (2016) cutoff
convention. Includes the Halpin et al. (2011) method for isolating the oldest
coherent cluster in Pb-loss–affected populations, and side-by-side concordias
for detrital work.

**Lu–Hf isotopes**
εHf(0), εHf(t), initial ¹⁷⁶Hf/¹⁷⁷Hf, single- and two-stage crustal model ages
(T<sub>DM</sub>, T<sub>DM</sub><sup>C</sup>), CHUR and depleted-mantle
evolution curves, and crustal reworking lines.

**Ti-in-zircon thermometry**
Ferry & Watson (2007) and the pressure-corrected Crisp et al. (2023)
calibrations, with analytical and population uncertainties.

**Trace elements and REE**
Chondrite-normalized multi-element (spider) patterns with three normalization
references, Eu/Eu\* and Ce/Ce\* anomalies, and tecto-magmatic discrimination
diagrams after Grimes et al. (2015).

**Detrital and provenance tools**
KDE and PDP age distributions, stacked KDEs (with groups), automatic peak
detection, maximum depositional ages, similarity matrices between samples, and
radial plots (Galbraith) with central age and mixture modelling.

**Figure production**
Every diagram is editable in place — legends, labels, annotations, shapes, zoom
insets, per-view axis limits, frozen framing, colour ramps and per-sample
settings. Diagrams can be assembled into multi-panel figures in the built-in
compositor and exported as vector PDF or SVG.

**Data handling**
Excel import (detects header rows and splits stacked samples), multi-sheet
`.xlsx` export at full precision, analysis sets with rules and per-sample
scope, a texture catalogue, manual exclusions with a recorded reason, and an
automatic data-QA pass that flags physically impossible inputs.

---

## Getting started

ZirClock ships with its own documentation, available from the **Help** menu:

- **User guide (PDF)** — an illustrated walkthrough of the whole workflow.
- **Theory & methods (PDF)** — the mathematics and geometry behind every
  calculation and diagram, with the equations as implemented and their
  references.
- **Reference values & constants** — the decay constants, reservoir parameters
  and normalization values in use.

A **Methods & references** generator (menu *Export*) drafts a methods
paragraph tailored to your project's actual settings, with the matching
citation list — a starting point for the methods section of a manuscript.

Projects are saved as `.zirclock` files; double-clicking one opens it in
ZirClock.

All algorithms are reimplemented independently from the published equations;
no source code from other programs is used.

---

## Running from source

ZirClock is a single Python file (`main.py`) built on PyQt6 and matplotlib.
With Python 3.12 or later:

```bash
python -m venv .venv
.venv/bin/pip install -r requirements.txt      # Windows: .venv\Scripts\pip
.venv/bin/python main.py                       # Windows: .venv\Scripts\python main.py
```

The installers are built with PyInstaller: `build_win.ps1` (Windows, also needs
Inno Setup 6) and `build_mac.sh` (macOS). Each must run on its own system.

---

## Reporting bugs

Please [open an issue](../../issues). The most useful reports include what you
did, what you expected and what happened instead; a screenshot if the problem
is visual; and your system (Windows 10 or 11, or your macOS version and Mac
model). If the problem only happens with particular data, attaching a project
file that reproduces it is the fastest route to a fix — but only if you are
comfortable sharing that data.

---

## How to cite

A formal citation will be added upon publication. Until then, please cite
ZirClock as:

> Espejo Bautista, G. (2026). *ZirClock: zircon petrochronology* (version 3.0)
> [Computer software]. https://github.com/zirclock-software/zirclock

GitHub's **Cite this repository** button (from [CITATION.cff](CITATION.cff))
gives the same reference in other formats.

---

## License

Copyright © 2026 Guillermo Espejo Bautista.

ZirClock is free software: you can redistribute it and/or modify it under the
terms of the [GNU General Public License](LICENSE) as published by the Free
Software Foundation, either version 3 of the License, or (at your option) any
later version. It is distributed in the hope that it will be useful, but
**without any warranty**.

The installers bundle third-party components under their own licenses (PyQt6,
GPL v3; Qt, LGPL v3; PyMuPDF, AGPL v3; matplotlib, NumPy, SciPy, pypdf,
openpyxl and Pillow under permissive licenses); the list is in
[packaging/LICENSE.txt](packaging/LICENSE.txt).

**Author:** Guillermo Espejo Bautista ·
[ORCID 0000-0001-9206-5108](https://orcid.org/0000-0001-9206-5108) ·
gespejo@geociencias.unam.mx
**Beta testers:** Luigi A. Solari · Carlos Ortega-Obregón
**Developed with** Claude (Anthropic).
