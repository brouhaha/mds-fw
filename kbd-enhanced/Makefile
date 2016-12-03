all: 104675-001.bin

hexdiff: 104675-001.orig.bin 104675-001.bin
	hexdiff 104675-001.orig.bin 104675-001.bin

104675-001.dis: 104675-001.orig.bin
	d48 -1 -d 104675-001.orig
	mv 104675-001.orig.d48 104675-001.dis

104675-001.p: kbd.asm
	asl -olist 104675-001.lst -o 104675-001.p kbd.asm

%.bin: %.p
	p2bin -r 0x0000-0x03ff $<

check: 104675-001.bin
	sha256sum -c kbd.sha256

clean:
	rm -f 104675-001.p 104675-001.bin 104675-001.lst
