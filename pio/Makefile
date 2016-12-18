all: check

pio220.p: pio.asm
	asl -D mod220 -L -olist pio220.lst -o pio220.p pio.asm

pio230.p: pio.asm
	asl -D mod230 -L -olist pio230.lst -o pio230.p pio.asm

104566-001.p: pio.asm
	asl -D m104566_001 -L -olist 104566-001.lst -o 104566-001.p pio.asm

%.bin: %.p
	p2bin -r 0x0000-0x03ff $<

check: pio220.bin pio230.bin 104566-001.bin
	sha256sum -c pio.sha256

clean:
	rm -f *.p *.bin *.lst

104566-001.dis: 104566-001.orig.bin
	d48 104566-001.orig
	mv 104566-001.orig.d48 104566-001.dis

hexdiff: 104566-001.orig.bin 104566-001.bin
	hexdiff 104566-001.orig.bin 104566-001.bin

