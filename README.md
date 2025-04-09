# Lab Exercises for FPGAs

These are a few lab exercises to get started with the Pynq Z1 FPGA board.  They are primarily targeted at the course EE5332 at IIT Madras, but may be generally useful to anyone working with these boards (or any other boards for that matter).  They are not a replacement for the official Pynq tutorials, but are targeted at a very specific use case corresponding to this course, so it is quite likely some things are not as per normal recommendations or even correct.

## Exercises

- [Basic Verilog example](counter/) and using ILA / VIO
- [Simple combinational adder](adder/) with Pynq
- [Streaming multiplier](stream_mult/) with Pynq
- FFT 

## Board Setup

These examples are built mostly around the [Pynq Z1 board](https://digilent.com/shop/pynq-z1-python-productivity-for-zynq-7000-arm-fpga-soc/), and it is assumed that you have followed the instructions for [board setup](https://pynq.readthedocs.io/en/latest/getting_started/pynq_z1_setup.html).  Most of the steps here can be performed without physical access to the board.  While this is a good general purpose board for learning, please note that there are probably better boards available now: in particular the Pynq Z2 already exists, as does the Pynq ZU, and there are possibly other less expensive boards that may or may not be Pynq compatible.  This tutorial should not be taken as a specific recommendation to acquire these boards specifically.

---

© 2025 Nitin Chandrachoodan, IIT Madras
This work is licensed under a Creative Commons Attribution 4.0 International License.

[![License: CC BY 4.0](https://licensebuttons.net/l/by/4.0/88x31.png)](https://creativecommons.org/licenses/by/4.0/)
