# Simple Adder with Pynq

The purpose of this exercise is to introduce the use of the Pynq operating environment and how to use it to transfer data into and out of a module on the programmable logic in the FPGA.  

This document does not explain:

- what Pynq is
- how it works
- how to write TCL scripts (except to encourage you to try and modify the ones here)
- how a memory map works

Instead, it takes you through a series of steps that will help you to:

- compile a Vitis HLS C++ source file into an IP module
- generate a bitstream and hardware handoff file required to program the Pynq Z1 FPGA board
- show how to put this design onto the FPGA board using Python for programming
- communicate with the module through Pynq to add two numbers

## Step 1: Environment

Ensure that your Xilinx environment has been set up properly.  You should be able to run the commands `vivado` and `vitis_hls` from the command line.  This exercise assumes that:

- You are running on Linux (or a close enough environment like Windows Subsystem for Linux).  
- You are using the command line and know how to type commands at the terminal.
- You do not have GUI access (not a problem if you do, but the commands assume you are using a terminal).

All examples here have been tested with Vivado 2021.1.  Other versions *may* work.  You are encouraged to test them out, but it is unlikely that these scripts will be changed based on this.

## Step 2: Compiling the HLS module for the adder

The adder module is a very trivial combinational circuit that adds two numbers.  **However**, there is a twist here: the way the inputs are provided to the module.  In this example, we are going to put a wrapper module around the adder that can provide inputs.  In the HDL based example with the counter, we directly used VIO signals to provide the control to the module.  Here we would like to provide the inputs from a processor that is running a program.

First we need to compile the HLS module.  There is a script for doing this in the `adder/hls` directory.  You need to do:

```sh
cd hls    # Assuming you are already in the `adder` directory
vitis_hls -f vhls.tcl
```

This assumes that there is a directory called `build` at the same level as the `hls` directory.  The adder module is compiled into Verilog code, and then packaged into an IP core, which is then placed under the `build` directory.

## Step 3: Generating the bitstream for FPGA programming

There is another script called `vivado_proj.tcl` that compiles and generates the bitstream file for programming the FPGA.  This is in the `hls` directory as well.  To compile it, run:

```sh
cd hls    # If not already there
vivado -mode batch -source vivado_proj.tcl
```

This should take about 5-10 minutes (depending on the load on your system).  After this is done, it should have generated two files in the `build/vivado` directory:

- `add_pynq.bit`
- `add_pynq.hwh`

## Step 4: Connecting to the Pynq board

It is assumed that the Pynq board has already been powered on and connected to the network using an ethernet cable.  This may either be on the campus LAN, or it could be on your router if you are using your own system.  Either way, it is assumed you know the IP address of the system: here I will assume it is 192.168.0.21.

Use a web browser and type in `http://192.168.0.21/` in the URL bar to go to the address of your board.  It should redirect you to a Jupyter notebook interface, where you can log in using the password `xilinx` (this is the default password on Pynq images).

## Step 5: Input/Output testing

It is assumed that you already understand the basics of how memory mapping works:  When the CPU tries to *dereference* a pointer (say something like `int *a; *a = 10'` in C), what actually happens is:

- `a` has an address assigned to it - this is the address of a memory location.  Due to the fact that operating systems use *virtual memory*, we may only know the *virtual address* of this location, and we need some other way by which we can convert this to a *physical* address.  
- Pynq is a set of libraries for Python that provide us with the ability to do so: there is a way to directly access a given memory location even though the underlying OS has virtualized it.  A nice set of Python functions is provided that abstract all this away for us.

In our case, we need to do the following