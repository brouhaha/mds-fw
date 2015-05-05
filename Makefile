all: ioc-a50.bin ioc-a51.bin ioc-a52.bin ioc-a53.bin

hexdiff-a50: ioc-a50.bin
	hexdiff ioc-a50.bin ../ioc_a50_104692-001.bin

hexdiff-a51: ioc-a51.bin
	hexdiff ioc-a51.bin ../ioc_a51_104692-002.bin

hexdiff-a52: ioc-a52.bin
	hexdiff ioc-a52.bin ../ioc_a52_104692-003.bin

hexdiff-a53: ioc-a53.bin
	hexdiff ioc-a53.bin ../ioc_a53_104692-004.bin

ioc-a50.bin: ioc-a50.p
	p2bin -r 0x0000-0x07ff ioc-a50.p

ioc-a51.bin: ioc-a51.p
	p2bin -r 0x0800-0x0fff ioc-a51.p

ioc-a52.bin: ioc-a52.p
	p2bin -r 0x1000-0x17ff ioc-a52.p

ioc-a53.bin: ioc-a53.p
	p2bin -r 0x1800-0x1fff ioc-a53.p

ioc-a50.p: ioc-a50.asm
	asl -L ioc-a50.asm

ioc-a51.p: ioc-a51.asm
	asl -L ioc-a51.asm

ioc-a52.p: ioc-a52.asm
	asl -L ioc-a52.asm

ioc-a53.p: ioc-a53.asm
	asl -L ioc-a53.asm
