# NSYSU-115-1-BRAIN-COMPUTER-INTERFACE-PRINCIPLES-AND-PRACTICE

# SSVEP-Based Sudoku Experiment (Psychtoolbox & MATLAB)

A MATLAB-based brain-computer interface (BCI) stimulation interface for solving Sudoku using **Steady-State Visually Evoked Potentials (SSVEP)**. Built on top of **Psychtoolbox-3**, this system provides a real-time, visual paradigm for SSVEP experimentation with manual keyboard bypass for testing.

---

## 📌 Key Features

- **SSVEP Visual Stimulation**: Renders 9 independent stimulus blocks flickering at target frequencies (8 Hz – 16 Hz) driven by sine waves.
- **Dynamic Board Tracking**: Automatically detects the next empty cell in the Sudoku grid and targets it sequentially.
- **Visual Cueing**: Highlights the current target cell in yellow prior to flickering stimulation to guide participant attention.
- **Keyboard Bypass Mode**: Real-time response logging via physical number keys (`1`–`9`) during flicker phase for rapid prototyping and validation without online EEG signal streaming.

---

## ⚙️ Paradigm Workflow
