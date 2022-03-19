# modal_microphone

## Reconstructing the project
- Clone project
- Open Vivado
- In TCL Console:
``` 
cd /.../modal_microphone
source rebuild.tcl
```
Method used for Vivado Git repo setup:
https://github.com/jhallen/vivado_setup

## Roadmap
- Testbench Simulation of pulse-density-modulated (PDM) Signals
- CIC Filter, reconstruct PDM back to 24-bit 48kHz signals
- FIR Filter compensation for CIC Magnitude Response and Anti-aliasing
- Modal Filters
- USB Audio
