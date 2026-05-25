# MUISCEQ — MATLAB-Based 7-Band Audio Equalizer

> A real-time audio equalizer built entirely in MATLAB, featuring a 7-band FIR filter bank,
> interactive GUI with gain sliders, built-in music presets, live FFT spectrum visualization,
> and a Simulink model for signal processing exploration.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Frequency Bands](#frequency-bands)
- [Music Presets](#music-presets)
- [File Structure](#file-structure)
- [How to Run](#how-to-run)
- [How It Works](#how-it-works)
- [Simulink Model](#simulink-model)
- [Requirements](#requirements)

---

## Overview

MUISCEQ processes an audio file through a bank of 7 FIR bandpass filters — one per
frequency band — each with an independently adjustable gain. The filtered bands are
summed and normalized to produce the equalized output. The GUI updates the spectrum
plots in real time as sliders are moved or presets are selected.

---

## Features

- 7-band FIR filter equalizer covering the full human hearing range (20 Hz – 20 kHz)
- Interactive MATLAB GUI with per-band gain sliders (0.5x – 2.0x)
- 5 built-in music presets: Flat, Rock, Jazz, Bass Boost, Classical
- Dual real-time plots:
  - Cumulative frequency response of the filter chain
  - FFT / Power Spectral Density of the filtered audio (PWelch method)
- Play, Stop, and Save processed audio directly from the UI
- Smart preset vs manual gain priority logic (via `prioritize_gains.m`)
- Simulink model for block-diagram-level signal processing

---

## Frequency Bands

| Band | Label      | Range          |
|------|------------|----------------|
| 1    | Sub        | 20 – 60 Hz     |
| 2    | Bass       | 60 – 250 Hz    |
| 3    | Low Mid    | 250 – 500 Hz   |
| 4    | Mid        | 500 – 2000 Hz  |
| 5    | Upper Mid  | 2000 – 4000 Hz |
| 6    | Presence   | 4000 – 6000 Hz |
| 7    | Brilliance | 6000 – 20000 Hz|

Each band uses a Kaiser-windowed FIR filter (order 100, beta 0.5) designed with `fir1`.
Band 1 uses a low-pass filter, Band 7 uses a high-pass filter, and Bands 2–6 use bandpass filters.
Zero-phase filtering is applied via `filtfilt` to avoid phase distortion.

---

## Music Presets

| Preset     | Sub  | Bass | Low Mid | Mid  | Up Mid | Presence | Brilliance |
|------------|------|------|---------|------|--------|----------|------------|
| Flat       | 1.0  | 1.0  | 1.0     | 1.0  | 1.0    | 1.0      | 1.0        |
| Rock       | 0.8  | 0.9  | 1.2     | 1.5  | 1.4    | 1.3      | 1.2        |
| Jazz       | 0.9  | 1.1  | 1.0     | 1.3  | 1.2    | 1.1      | 1.0        |
| Bass Boost | 1.3  | 1.0  | 1.0     | 0.9  | 0.8    | 0.8      | 0.7        |
| Classical  | 1.0  | 1.0  | 1.0     | 1.1  | 1.2    | 1.3      | 1.4        |

> Moving any slider after selecting a preset activates **manual override** for that band.
> Selecting a new preset resets all bands back to the preset values.
> This priority logic is handled by `prioritize_gains.m`.

---

## File Structure

```
MUISCEQ/
│
├── README.md
│
├── src/
│   ├── ProjectMusic.m          <- Main equalizer (dual-plot: freq response + FFT)
│   ├── audio_equalizer_UI.m    <- Updated version with real-time playback refresh
│   └── prioritize_gains.m      <- Preset vs manual gain priority logic
│
├── simulink/
│   ├── PRMU.slxc               <- Simulink model cache (open the .m file first)
│   └── EQUALIZER.7z            <- Full Simulink project (extract before use)
│
└── docs/
    └── (add screenshots or report here)
```

---

## How to Run

### MATLAB GUI (Recommended)

1. Place your audio file in the same folder as the script and rename it `2.mp3`
   (or edit the `audioread` line to match your filename).

2. Open MATLAB and navigate to the `src/` folder.

3. Run either script:

```matlab
% Option A — Dual-plot version (frequency response + FFT)
ProjectMusic

% Option B — Real-time playback update version
audio_equalizer_UI
```

4. Use the sliders to adjust per-band gain, or select a preset from the dropdown.

5. Click **Play** to hear the processed audio, **Stop** to stop playback,
   and **Save Audio** to export the result as an MP3.

### Simulink Model

1. Extract `simulink/EQUALIZER.7z` to get the full Simulink project files.
2. Open MATLAB, navigate to the extracted folder, and open the relevant `.m` file
   to launch the Simulink model.
3. Run the simulation to observe block-level signal processing.

---

## How It Works

```
Audio File (.mp3)
      |
      v
[ Band 1: Low-pass  20–60 Hz   ] x gain_1 --|
[ Band 2: Bandpass  60–250 Hz  ] x gain_2 --|
[ Band 3: Bandpass 250–500 Hz  ] x gain_3 --|
[ Band 4: Bandpass 0.5–2 kHz   ] x gain_4 --+--> SUM --> Normalize --> Output
[ Band 5: Bandpass 2–4 kHz     ] x gain_5 --|
[ Band 6: Bandpass 4–6 kHz     ] x gain_6 --|
[ Band 7: High-pass 6–20 kHz   ] x gain_7 --|
```

All filters use `filtfilt` for zero-phase response (no time-domain distortion).
The output is normalized by its peak absolute value to prevent clipping.

---

## Simulink Model

The `PRMU.slxc` file is a compiled Simulink cache. To open it:

1. Extract `EQUALIZER.7z` first — this contains the full `.slx` model file.
2. Open the extracted folder in MATLAB and run the associated `.m` file
   matching your preference mode (as noted in the original README).

---

## Requirements

- MATLAB R2020a or later
- Signal Processing Toolbox (for `fir1`, `filtfilt`, `freqz`, `pwelch`)
- Audio Toolbox (for `audioread`, `audiowrite`, `audioplayer`)
- Simulink (for the `.slxc` / `.slx` model only)

---

*MIST — Department of Electrical, Electronic and Communication Engineering*
