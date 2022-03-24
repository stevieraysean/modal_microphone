# modal_microphone
Build Environment
Vivado v2021.2 (64-bit)


## Reconstructing the project
- Clone project
- Open Vivado
- In TCL Console:
``` 
cd /.../modal_microphone
source rebuild.tcl
```
may need to delete vivado_project directory before source command, or use -force arguement.

Method used for Vivado Git repo setup:
https://github.com/jhallen/vivado_setup

## Roadmap
- Testbench Simulation of pulse-density-modulated (PDM) Signals
- CIC Filter, reconstruct PDM back to 24-bit 48kHz signals (support 96kHz, 192kHz also)
- Half-band filters to further reduce sample-rate
- FIR Filter compensation for CIC Magnitude Response and Anti-aliasing
- Abstract construction of X Microphone elements basic on Spherical Coordinates
- Testbench feeding X microphones different frequencies
- Summing stages for X microphones
- FIR Filters for Spherical Harmonic Modes
- USB Audio
