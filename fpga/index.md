# Basic FPGA Example

This exercise consists of running a simple Verilog counter on the FPGA.  The counter requires a clock, which can either be the basic incoming FPGA clock at 125 MHz, or else a pulse signal that can be driven manually using the VIO.

The purpose of this exercise is to introduce you to the basics of compiling and running a design on the FPGA board, as well as basic debugging using the Integrated Logic Analyzer (ILA) and manual control using the Virtual Input/Output (VIO) mechanism.

## How to run

The source code is in the `src/` folder.  Go through this to understand the required functionality of the counter.  

- `counter.sv`: this is the actual counter module.  Has some control signals that should be self-explanatory.
- `counter_top.sv`: top level module that includes the VIO and ILA for control and debug.  Required only for implementation on the FPGA.  In particular, this is not meant to be simulated, which is why it is distinct from the base module.
- `counter_tb.sv`: test bench for the counter.
- `PYNQ-Z1_C.xdc`: a standard constraints file for the Pynq Z1 board - downloaded from the vendor website.

The folder `scripts/` contains several TCL scripts to create the project and generate the bit file.  This is because this approach is more structured than using Vivado.  In particular, since lab access does not provide you with a GUI but only a terminal, you cannot run the GUI version of Vivado.  

The scripts are hopefully easy enough to understand and modify if needed.  For now, the only real thing you need to do is type:

```sh
make
```

on the command line.  Assuming that you have the Xilinx tools set up properly in your system path, this should result in the files getting compiled, and finally a `.bit` file (bitstream) will be generated.
