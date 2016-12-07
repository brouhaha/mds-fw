all: 9100101.bin

hexdiff: 9100101.orig.bin 9100101.bin
	hexdiff 9100101.orig.bin 9100101.bin

9100101.dis: 9100101.orig.bin
	d48 -1 -d 9100101.orig
	mv 9100101.orig.d48 9100101.dis

9100101.p: 9100101.asm
	asl -l -o 9100101.p 9100101.asm >9100101.lst

%.bin: %.p
	p2bin -r 0x0000-0x03ff $<

check: 9100101.bin
	sha256sum -c 9100101.sha256

clean:
	rm -f 9100101.p 9100101.bin 9100101.lst
