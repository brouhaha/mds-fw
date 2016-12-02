all: pio230.bin pio230.bin.orig

pio220.bin.orig: pio220.hex
	srec_cat pio220.hex -intel -o pio220.bin.orig -binary

pio230.bin.orig: pio230.hex
	srec_cat pio230.hex -intel -o pio230.bin.orig -binary

hexdiff: pio230.bin
	hexdiff pio230.bin pio230.bin.orig

104566-001.dis: 104566-001.orig.bin
	d48 104566-001.orig
	mv 104566-001.orig.d48 104566-001.dis

pio220.p: pio.asm
	asl -D mod220 -olist pio220.lst -o pio220.p pio.asm

pio230.p: pio.asm
	asl -D mod230 -olist pio230.lst -o pio230.p pio.asm

104566-001.p: pio.asm
	asl -D m104566_001 -olist 104566-001.lst -o 104566-001.p pio.asm

%.bin: %.p
	p2bin -r 0x0000-0x03ff $<

check: pio220.bin pio230.bin 104566-001.bin
	sha256sum -c pio.sha256
