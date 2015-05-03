all: ioc-a50.bin ioc-a51.bin

hexdiff-a50: ioc-a50.bin
	hexdiff ioc-a50.bin ../ioc_a50_104692-001.bin

hexdiff-a51: ioc-a51.bin
	hexdiff ioc-a51.bin ../ioc_a51_104692-002.bin

ioc-a50.bin: ioc-a50.p
	p2bin -r 0x0000-0x07ff ioc-a50.p

ioc-a51.bin: ioc-a51.p
	p2bin -r 0x0800-0x0fff ioc-a51.p

ioc-a50.p: ioc-a50.asm
	asl -L ioc-a50.asm

ioc-a51.p: ioc-a51.asm
	asl -L ioc-a51.asm
