all: pio230.bin pio230.bin.orig

pio230.bin.orig: pio230.hex
	srec_cat pio230.hex -intel -o pio230.bin.orig -binary

hexdiff: pio230.bin
	hexdiff pio230.bin pio230.bin.orig

pio230.bin: pio230.p
	p2bin -r 0x0000-0x03ff pio230.p

pio230.p: pio230.asm
	asl -L pio230.asm
