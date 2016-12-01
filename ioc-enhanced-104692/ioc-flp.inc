; disk parameters
maxtrk	equ	77
maxsect	equ	26


; disk I/O parameter block
iopbsiz	equ	5

iopbocw	equ	0	; IOPB offset, channel word
sectseq	equ	040h	;   sector number remap via RAM, used for format only

iopboin	equ	1	; IOPB offset, diskette instruction
iopbosc	equ	2	; IOPB offset, sector count
iopbotk	equ	3	; IOPB offset, track
iopbose	equ	4	; IOPB offset, sector
