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
may need to delete modal_microphone_vivado directory before source command, or use -force arguement.

Method used for Vivado Git repo setup:
https://github.com/jhallen/vivado_setup

## Roadmap
- [x] Testbench Simulation of pulse-density-modulated (PDM) Signals
- [x] CIC Filter, reconstruct PDM back to 24-bit 48kHz signals (support 96kHz, 192kHz also)
- [x] Flexible FIR Filter design
- [x] Half-band filters to further reduce sample-rate (TODO: rate reduction)
- [x] FIR Filter compensation for CIC Magnitude Response and Anti-aliasing
- [ ] FIR Filters for Spherical Harmonic Modes
- [ ] Abstract construction of X Microphone elements basic on Spherical Coordinates
- [ ] Testbench feeding X microphones different frequencies
- [ ] Summing stages for X microphones
- [ ] USB Audio

### General Module TODOs:
- [ ] Calculate Bit Growth for truncation ranges
- [x] Rounding before truncation (done for CIC, TODO: FIR)
- [ ] Reset Signals
