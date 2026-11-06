# NSYSU-115-1-BRAIN-COMPUTER-INTERFACE-PRINCIPLES-AND-PRACTICE

# SSVEP-Based Sudoku BCI Experiment Engine

![MATLAB](https://img.shields.io/badge/MATLAB-R2018b%2B-orange.svg)
![Psychtoolbox](https://img.shields.io/badge/Psychtoolbox-PTB--3-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

An open-source MATLAB and Psychtoolbox-3 (PTB-3) implementation of a **Steady-State Visually Evoked Potential (SSVEP)** Brain-Computer Interface (BCI) system designed for solving interactive Sudoku puzzles. 

This repository provides a complete visual stimulation engine featuring real-time matrix updates, target cell cueing, customizable flicker frequency mapping, and built-in keyboard bypass for offline testing and hardware validation.

---

## 📑 Table of Contents
- [Overview](#-overview)
- [Key Features](#-key-features)
- [System Architecture & Flow](#-system-architecture--flow)
- [SSVEP Frequency Mapping](#-ssvep-frequency-mapping)
- [Prerequisites & Installation](#-prerequisites--installation)
- [Usage & Controls](#-usage--controls)
- [Code Structure Analysis](#-code-structure-analysis)
- [Configuration & Customization](#-configuration--customization)
- [License](#-license)

---

## 🔬 Overview

Steady-State Visually Evoked Potentials (SSVEP) are signals natural to the brain's visual cortex that occur when attending to a visual stimulus flickering at a specific frequency. 

This project adapts the standard 3×3 grid stimulation layout to control a Sudoku solver. The system automatically steps through empty cells on a 9×9 Sudoku board, highlights the current target cell, presents 9 flickering target choices (numbers 1–9) operating at distinct frequencies (8–16 Hz), and updates the board upon choice selection.

---

## 🌟 Key Features

* **Dynamic Sudoku Solver Tracking**: Automatically identifies empty cells (`0`) in real-time, eliminating fixed array bounds and advancing dynamically until the puzzle is completed.
* **Two-Phase Trial Presentation**:
  * **Phase A (Target Cue)**: Highlights the current target cell in high-contrast yellow for 1.5 seconds to orient the participant.
  * **Phase B (SSVEP Stimulation)**: Displays 9 sinusoidal flickering boxes alongside real-time keypress detection.
* **Sinusoidal Visual Flickering**: Employs mathematically precise frame-by-frame sine wave calculations for smooth luminance modulation.
* **Hybrid Input Support (Validation Mode)**: Includes real-time keyboard polling (`KbCheck`) during stimulation to allow manual answer entry (keys `1`–`9`) without requiring an immediate online EEG classifier pipeline.
* **Robust Key Debouncing**: Prevents double-triggering across consecutive display frames via state-reset loops.

---

## 📐 System Architecture & Flow

```
+-------------------------------------------------------+
|                    1. Initial Setup                   |
|  - Screen Initialization, Keyboard Mapping, Key Names  |
+-------------------------------------------------------+
                           │
                           ▼
+-------------------------------------------------------+
|                  2. Start & Countdown                 |
|  - Title Screen -> 3-2-1 Countdown -> Fixation Cross  |
+-------------------------------------------------------+
                           │
                           ▼
+-------------------------------------------------------+
|                3. Target Identification               |
|  - Find first empty space (board == 0) in 9x9 grid    |
+-------------------------------------------------------+
                           │
             ┌─────────────┴─────────────┐
             │ Empty cells exist?        │
             └─────────────┬─────────────┘
                  YES      │      NO
                   │              └───────────────────────┐
                   ▼                                      ▼
+-------------------------------------+   +-------------------------------+
|       Phase A: Target Cue (1.5s)     |   |     Puzzle Completed Screen   |
| - Highlight target cell in Yellow   |   |   - Display 'Completed!' text |
+-------------------------------------+   +-------------------------------+
                   │                                      │
                   ▼                                      ▼
+-------------------------------------+                [ EXIT ]
|    Phase B: SSVEP Stimulation (5s)  |
| - Render 9 flickering targets (8-16Hz)|
| - Poll key inputs (1-9) or EEG data|
+-------------------------------------+
                   │
                   ▼
+-------------------------------------+
|        4. Board State Update        |
| - Write selected number into matrix |
| - Debounce keypress                 |
+-------------------------------------+
                   │
                   └──────────────────────────────────────┘
```

---

## ⚡ SSVEP Frequency Mapping

The 9 flickering boxes are organized in a standard 3×3 matrix on the screen, mapped to numbers `1` through `9`:

| Target Box Index | Target Number | Frequency (Hz) | Position (Grid Row, Col) |
| :---: | :---: | :---: | :---: |
| **1** | **1** | **8 Hz**  | Top-Left (1, 1) |
| **2** | **2** | **9 Hz**  | Top-Center (1, 2) |
| **3** | **3** | **10 Hz** | Top-Right (1, 3) |
| **4** | **4** | **11 Hz** | Mid-Left (2, 1) |
| **5** | **5** | **12 Hz** | Center (2, 2) |
| **6** | **6** | **13 Hz** | Mid-Right (2, 3) |
| **7** | **7** | **14 Hz** | Bottom-Left (3, 1) |
| **8** | **8** | **15 Hz** | Bottom-Center (3, 2) |
| **9** | **9** | **16 Hz** | Bottom-Right (3, 3) |

---

## 🛠️ Prerequisites & Installation

### Requirements
1. **MATLAB**: R2017b or newer (R2020b+ recommended).
2. **Psychtoolbox-3 (PTB-3)**: Installed and configured on your MATLAB environment.
   - For installation instructions, visit [Psychtoolbox.org](http://psychtoolbox.org/).

### Installation
Clone this repository to your local machine:
```bash
git clone https://github.com/your-username/ssvep-sudoku-matlab.git
cd ssvep-sudoku-matlab
```

---

## 🚀 Usage & Controls

1. Open MATLAB and navigate to the directory containing the project.
2. Run the main script:
   ```matlab
   sudoku_ssvep
   ```
3. **Interactive Controls**:
   - **Any Key**: Start experiment at the welcome screen.
   - **Keys `1` – `9`**: Input the desired number when the flickering stimuli appear.
   - **`ESC`**: Abort the experiment immediately and safely close display windows (`sca`).

---

## 🔍 Code Structure Analysis

- **Display Preferences**:
  ```matlab
  Screen('Preference', 'SkipSyncTests', 1);
  ```
  *Note: Skipped sync tests are enabled for development on non-dedicated graphical setups. Set this parameter to `0` during formal laboratory data acquisition.*

- **Sinusoidal Signal Modulation**:
  ```matlab
  if sin(2*pi*freq(k)*t) > 0
      color = white;
  else
      color = [50 50 50];
  end
  ```
  Modulates luminance states according to precise timing deltas (`t = GetSecs - t0`).

- **Dynamic Search Loop**:
  ```matlab
  [row, col] = find(board == 0);
  emptyPos = [row col];
  ```
  Scans remaining targets continuously without requiring hardcoded array indexing.

---

## 🔧 Configuration & Customization

You can easily adjust experiment parameters inside the main script:

* **Flicker Frequencies**: Update the `freq` array:
  ```matlab
  freq = [8 9 10 11 12 13 14 15 16]; % Adjust Hz per target
  ```
* **Stimulation Window Length**: Modify target presentation duration:
  ```matlab
  stimDuration = 5; % Duration in seconds
  ```
* **Box Layout & Sizes**: Adjust dimensions via `boxW`, `boxH`, `dx`, and `dy`.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
