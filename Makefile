all: ioc_a50.bin

ioc_a50.bin: ioc_a50.p
	p2bin -r 0x0000-0x07ff ioc_a50.p

ioc_a50.p: ioc_a50.asm
	asl -L ioc_a50.asm
