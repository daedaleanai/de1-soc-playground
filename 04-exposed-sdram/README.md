
Exposed SDRAM
=============

This system implements the Hard Processor System with the push buttons exposed
at `0xff200000`, 256KB of on-chip memory exposed at `0xc8000000`, and 64MB of
SDRAM at `0xc0000000`. Follow the instructions in the master README file to
install it in the target board. The sw subdirectory contains a program that
writes some data to this memory and reads it back from the level of Linux
userspace.
