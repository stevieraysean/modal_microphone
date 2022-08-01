# modal_microphone
Build Environment
Vivado v2021.2 (64-bit)


## Reconstructing the project
- Clone project
- Open Vivado
- In TCL Console:
``` 
cd /modal_microphone
source rebuild.tcl
```
may need to delete modal_microphone_vivado directory before source command, or use -force arguement.

depends on Arty A7-35t files from https://github.com/Digilent/vivado-boards

Method used for Vivado Git repo setup:
https://github.com/jhallen/vivado_setup

## Roadmap
- [x] Testbench Simulation of pulse-density-modulated (PDM) Signals
- [x] CIC Filter, reconstruct 1-bit PDM back to 24-bit 192kHz audio signal
- [x] Flexible FIR Filter design (generate from filter coeffieicents)
- [x] FIR Filter compensation for CIC Magnitude Response and Anti-aliasing
- [x] Abstract construction of multiple Microphone elements based on Spherical Coordinates
- [x] Summing stages for X microphones (done for 0th mode)
- [ ] FIR Filters for Spherical Harmonic Modes
- [ ] Testbench feeding X microphones different frequencies
- [ ] USB Audio / Ethernet

### General Module TODOs:
- [ ] Calculate Bit Growth for truncation ranges
- [x] Rounding before truncation (done for CIC, TODO: FIR)
