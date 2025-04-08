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

In our case, we need to do the following:

- Copy the `add_pynq.bit` and `add_pynq.hwh` files into the Pynq board.  Once you connect to Pynq, you will see a directory listing where you can *upload* these files.
- If the `add.ipynb` notebook is not already present, upload it from this directory.  Run the notebook.

### Notebook contents and observations:

The notebook does the following:

- Run the necessary commands to `import` the required Python modules
- Create an `Overlay` instance that takes care of programming
- View the register map.  This is an optional step: it is just for you to correlate how the Python interacts with the hardware, with the register map that was defined in Verilog.  Basically the register map tells Python the offset addresses of the different input and output parameters so that we can directly set or read their values.
- Create the proxy variable `adder_0` to make it easier to type the rest of the code.  Again: optional.
- Actually set the values for the `a` and `b` inputs by writing to the appropriate register values directly.  This is where the actual interaction with hardware over the AXI lite bus happens.
- Read back the result from the `c` output, again using AXI lite. 

As you can see, the steps for communicating with the AXI bus are abstracted out so that you do not even need to declare pointers, worry about memory addresses etc.  This is probably not a good thing if you want to learn how the hardware works, so please take the time to understand what is actually happening and how the data is being sent to the hardware.

Feel free to experiment by changing the values of `a` and `b`.  Also feel free to modify the underling HLS code, changing the functionality etc.

Note that if you change the number or names of the inputs or outputs, then you will need to modify the `vivado_proj.tcl` file to update the block design.  This is non-trivial, so attempt this only after you are sure you understand the rest of the design process.
