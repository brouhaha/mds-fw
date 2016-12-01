# mds-fw - Firmware for Intel MDS 800, Series II, Series III

Copyright 2016 Eric Smith <spacewar@gmail.com>

mds-fw development is hosted at the
[mds-fw Github repository](https://github.com/brouhaha/mds-fw/).


## Introduction

Before IBM PC compatible computers became ubiquitous, microprocessor
vendors sold proprietary microprocessor development systems.  Intel's
early offerings included the INTELLEC 4/MOD 4, INTELLEC 4/MOD 40,
INTELLEC 8/MOD 8, and INTELLEC 8/MOD 80, for the 4004, 4040, 8008, and
8080, respectively. In 1976 Intel introduced the MDS 800 Microcomputer
Development System, which was the first system to use Intel's
general-purpose bus standard, later known as Multibus, and Intel's
first system to support floppy disks, using the MDS-DOS subsystem and
ISIS operating system.  The MDS 800 was normally used with a serial
terminal such as the Beehive MiniBee, sold as the Intel INTELLEC
MDS-CRT.

In 1978, Intel introduced the INTELLEC Series II MDS, which used an
IPB-80 main processor board (8080-based). All Series II models other
than Model 210 also included an integrated 8080-based IOC (I/O
Controller), providing a built-in video terminal and a single-density
floppy controller (not used in all models).  Later models replaced the
IPB-80 main processor board with an 8085-based IPC-85.

Later Intel introduced the Series III MDS, which was a Series II
with an 8086 processor board (RPB-86 or RPC-86) added.


## IOC Firmware

The IOC has an 8080 processor that handles the keyboard, CRT display,
and integrated single-density floppy controller, and an 8041 or 8741
microcontroller which handles the optional printer, paper tape reader,
paper tape punch, and UPP (Universal PROM Programmer).

There are at least three released versions of the IOC 8080 firmware

* original (unenhanced) - part numbers unknown
* enhanced - part numbers 104593-001 through -004
* enhanced - part numbers 104688-001 through -004
* enhanced - part numbers 104692-001 through -004
* IOC-III - uses new version of IOC hardware - part numbers unknown

The enhanced firmware add improved console support with function
key macros and better cursor control

Presently this project has partially reverse-engineered source code
for the enhanced IOC, part numbers 104692-00x, in the ioc-enhanced
directory.

The source code is intended to be assembled using the
[Macroassembler AS](http://john.ccac.rwth-aachen.de:8000/as/).
Due to the use of long symbol names, it may not be possible to
assemble it with native assemblers.


## License information:

Copyright is asserted on the reverse-engineered source code, but not on
the original binary code provided in ROM, PROM, or EPROM by Intel.

This program is free software: you can redistribute it and/or modify
it under the terms of version 3 of the GNU General Public License as
published by the Free Software Foundation.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
