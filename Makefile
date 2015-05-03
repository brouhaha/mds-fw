all: ioc-a50.bin

ioc-a50.bin: ioc-a50.p
	p2bin -r 0x0000-0x07ff ioc-a50.p

ioc-a50.p: ioc-a50.asm
	asl -L ioc-a50.asm
