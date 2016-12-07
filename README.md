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
with an 8086 processor board (RPB-86 or RPC-86) added, the iPDS, which
was a more compact, portable development system, and the Series IV,
which was significantly different.


## Firmware

This project contains reverse-engineered "source code", with varying degrees
of completion of the reverse-engineering.  However, all of the source code
is verified to assemble to the original binary.  The makefile in each
subdirectory has a "check" target which will compare a SHA256 hash of the
assembled binary file to the hash of the original firmware.

This includes both 8080 code and 8041 UPI code, which are intended to
be assembled using the
[Macroassembler AS](http://john.ccac.rwth-aachen.de:8000/as/).
Due to the use of long identifiers, it may not be possible to assemble
the source code with native assemblers, which are typically limited to
six-character identifiers.


### IOC Firmware

With the exception of the Model 210, Series II and Series III MDS
machines have an IOC module with its own 8080 processor which handles
the keyboard, CRT display, and integrated single-density floppy
controller.

There are at least six released versions of the IOC 8080 firmware:

* original (unenhanced, 8257 DMAC) - part numbers unknown
* original (unenhanced, 8237 DMAC) - part numbers unknown
* enhanced - part numbers 104593-001 through -004
* enhanced - part numbers 104688-001 through -004
* enhanced - part numbers 104692-001 through -004
* IOC-III - uses new version of IOC hardware - part numbers unknown

With the possible exception of the IOC-III, the firmware is supplied
as four 2616 or 2716 EPROMs, installed in locations E50 through E53.

The enhanced firmware add improved console support with function
key macros and better cursor control, and supports either the 8257 or
8237 DMA controller.

Presently this project has partially reverse-engineered source code
for the enhanced IOC, part numbers 104692-00x, in the ioc-enhanced
directory.


### Character Generator

The IOC has a 2708 (or 2608) EPROM used as the character generator
for the CRT. The characters are 6x8 pixels, but some pixels may be
shifted a half pixel position to the right, under the control of the
two LSBs of the EPROM data.

In the chargen directory there is a Python 3 script "view" which
renders the character set in a PDF table.


### PIO Firmware

THe IOC also has an masked-ROM 8041A "UPI" microcontroller which
handles the optional printer, paper tape reader, paper tape punch, and
UPP (Universal PROM Programmer).

Presently this project has partially reverse-engineered source code
for the PIO 8041A, part number 104566-001, in the pio directory.

The pio.asm source code contains conditional assembly directives used
by the Makefile to assemble three different versions of pio firmware.
The Intel part numbers of the other two versions are unknown, but they
were dumped from Series II Model 220 and Model 230 machines.  The
differences between the versions are fairly minor. The 104566-001
version is believed to be the most recent, and is expected to work
properly in any Series II or Series III MDS that uses an IOC module.


### Keyboard firmware

The keyboard has an EPROM-based 8741A "UPI" microcontroller which
scans the key matrix and provides parallel data to be read by the IOC
firmware.

Old Series II MDS keyboards have a repeat key for manual repeat.  The
enhanced keyboard replaces the repeat key with a function key, and
performs auto-repeat.

Presently this project has partially reverse-engineered source code
for the unenhanced keyboard 8741A, part number 9100101, in the kbd
directory, and for the enhanced keyboard 8741A, part number 104675-001,
in the kbd-enhanced directory.

Note that the MDS keyboard uses a "bit-paired" arrangement, as common
for ASCII equipment in the 1960s and 1970s (e.g., Teletype model 33),
rather than the now-ubiquitous "typewriter-paired" arrangment.  This
makes use of the MDS keyboard awkward for experienced typists. The key
matrix position to character code table in the 8741A could be altered,
and different keycaps installed, to obtain a typewriter-paired
arrangement.


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
