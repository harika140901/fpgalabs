# Streaming Multiplier with Pynq

This exercise builds on top of the `adder` example.  Here we create a multiplier that reads inputs from AXI stream interfaces, and generates output on an AXI stream.  It is assumed that you are already familiar with the setup in the `adder` design to compile and generate the bitstream, and to connect to the Pynq board.

## Step 1: Environment

Set up your Xilinx environment as done for the `adder` design.

## Step 2: Compiling the HLS module for the streaming multiplier

The design is a very simple combinational multiplier.  However, unlike the adder that took inputs through the `axi_lite` AXI interface, here we use the AXI stream interface that can be used for a FIFO type data transfer.  That is, we can pump data continuously into the stream, and as long as valid data is present the multiplier will read the values and perform the operation.

This is not purely combinational: it generates output only when there is valid input.  However, it does not require a separate `start` signal, and is always ready to work.

First we need to compile the HLS module.  There is a script for doing this in the `stream_mult/hls` directory.  You need to do:

```sh
cd hls    # Assuming you are already in the `stream_mult` directory
vitis_hls -f vhls.tcl
```

This assumes that there is a directory called `build` at the same level as the `hls` directory.  The multiplier module is compiled into Verilog code, and then packaged into an IP core, which is then placed under the `build` directory.

## Step 3: Generating the bitstream for FPGA programming

There is another script called `vivado_proj.tcl` that compiles and generates the bitstream file for programming the FPGA.  This is in the `hls` directory as well.  To compile it, run:

```sh
cd hls    # If not already there
vivado -mode batch -source vivado_proj.tcl
```

This should take about 5-10 minutes (depending on the load on your system).  After this is done, it should have generated two files in the `build/vivado` directory:

- `mult_stream_pynq.bit`
- `mult_stream_pynq.hwh`

## Step 4: Connecting to the Pynq board

It is assumed that the Pynq board has already been powered on and connected to the network using an ethernet cable.  This may either be on the campus LAN, or it could be on your router if you are using your own system.  Either way, it is assumed you know the IP address of the system: here I will assume it is 192.168.0.21.

Use a web browser and type in `http://192.168.0.21/` in the URL bar to go to the address of your board.  It should redirect you to a Jupyter notebook interface, where you can log in using the password `xilinx` (this is the default password on Pynq images).

## Step 5: Input/Output testing

We first load the `mult_demo.ipynb` if not already present on the Pynq board.  In this file, we can see that there is a little more complexity than in the adder demo.

In particular, the multiplier interfaces are of type AXI stream: they use a handshaking protocol to transfer data.  That means we need some way to convert the data that is inside the CPU memory into a stream of data so it can be fed to the multiplier.

One way to do this is to use the Direct Memory Access (DMA) IP core from Xilinx.  It is capable of acting as a bus master, meaning that it can directly read data from the PS memory without CPU intervention.  This data can then be streamed out using an AXI stream interface: hence the name "Memory Map to Streaming" or MM2S.  Similarly, we can use the "Stream to Memory Map" interface to get streaming data back from our multiplier IP and send it to the PS memory through the DMA.

The TCL script sets all this up, and now we just need to access it from Pynq.  Using DMA requires a little additional setup, but this is handled by the Pynq libraries.

### Memory Allocation

The Python notebook contains the required setup for DMA transfers.  One important point here is that DMA requires the actual physical address of the memory as it bypasses the Linux OS that is running on the ARM processor, and cannot use virtual addresses.  This means that just using a pointer declared in Linux won't work, as this works with virtual addresses.  Instead, we need to use a special library that has been created for Pynq that is able to access the physical address of an array.  This is done using the `allocate` function.

Once this is done, the DMA can be used to transfer data into the IP.  There is no separate start/stop signaling - the IP is permanently ready to accept data, multiply it, and return the result, all using streams.

### Things to try

- Change the allocation size
- Add some timing functions to see how long it takes
- Change the order of dma send/receive, and switch the position of the wait() function
