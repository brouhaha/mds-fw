	cpu	8080

	include	ioc-io.inc
	include	ioc-flp.inc
	include ioc-mac.inc
	
; entry points in ROM 0

s000b	equ	0000bh
romt2c	equ	0002bh

; entry points in ROM 2

cmd0f	equ	01003h	; cmd 00f - not documented
s1006	equ	01006h
s1012	equ	01012h

; entry points in ROM 3

s1800	equ	01800h
keyc	equ	01809h	; cmd 012h - Requests data byte input from the keyboard.
kstc	equ	0180ch	; cmd 013h - Returns keyboard status byte to master.
s180f	equ	0180fh
s1815	equ	01815h
s181b	equ	0181bh

; RAM, 4000h..5fffh

	org	04102h
iopbcnt	ds	1	; count of IOPB bytes received

	org	041f1h
systatb	ds	1

	org	041f7h
moshad	ds	1	; RAM shadow of miscout register
iopb	ds	iopbsiz

	org	05230h
scrbeg	ds	24*80	; start of screen buffer
scrend:			; ends at 05a00h (last byte used 059ffh)

; DBB command byte
cdbbrqi	equ	080h	; host requests that IOC generate command completion interrupt

cpacify	equ	000h	; Reset IOC and its devices.
cereset	equ	001h	; Reset device-generated error (not used by standard devices).
csystat	equ	002h	; Returns subsystem status byte to master.
cdstat	equ	003h	; Returns device status byte to master.
csrqdak	equ	004h	; Enables input of device int ack mask from master.
csrqack	equ	005h	; Clears IOC subsystem interrupt request.
csrq	equ	006h	; Tests ability of IOC to forward an interrupt request to the master.
cdecho	equ	007h	; Tests ability of IOC to echo data byte sent by master.
ccsmem	equ	008h	; Requests IOC to checksum on-board ROM. Returns pass/fail.
ctram	equ	009h	; Requests IOC to test on-board RAM. Returns pass/fail.
csint	equ	00ah	; Enables specific device interrupt from IOC.

ccrtc	equ	010h	; Requests data byte output to the CRT monitor.
ccrts	equ	011h	; Returns CRT status byte to master.

ckeyc	equ	012h	; Requests data byte input from the keyboard.
ckstc	equ	013h	; Returns keyboard status byte to master.

cwpbc	equ	015h	; Enables input from master of IOPB Channel Word byte.
cwpbcc	equ	016h	; Enables input from master of subsequent IOPB byte.
cwdbc	equ	017h	; Enables input of diskette write bytes from master.
crdbc	equ	019h	; Enables output of diskette read bytes to master.
crrsts	equ	01bh	; Returns diskette result byte to master.
crdsts	equ	01ch	; Returns diskette device status byte to master.

; SYSTAT bits
deverr	equ	080h	; device failed to respond to command, use DSTAT cmd for details
illcmd	equ	040h	; illegal command code received from master
illdat	equ	020h	; unexpected data from master, or cmd when data expected
illmsk	equ	010h	; illegal interrupt reset mask from SRQDAK command
; bits 3..0 reserved

	org	00800h

l0800:	jmp	ereset
s0803:	jmp	xs0803
s0806:	jmp	xs0806
s0809:	jmp	xs0809
s080c:	jmp	xs080c
	jmp	xs080f		; XXX no external references?

	dw	d099e


; get one byte of data from master, return in A
; BC = address in which to set illegal data transfer flag if command received
mget1d:	out	iocbusy
l0816:	in	dbbstat		; has the master written a byte yet?
	ani	dbbibf
	jnz	l0816		; no, loop
	
	in	dbbstat		; is the byte a command?
	ani	dbbcd
	jz	l0828		; yes, error

	in	dbbin		; read the data byte
	cma			; (hw negative logic)
	ret

l0828:	ldax	b
	ori	020h
	stax	b
	jmp	ereset


; set miscout.unkout4
s082f:	call	s083d
	mvi	c,unkout4

s0834:	lxi	h,moshad
	mov	a,m
	ora	c	
	mov	m,a	
	out	miscout
	ret


; clear miscout.unkout4
s083d:	mvi	c,(~unkout4)&0ffh
s083f:	lxi	h,moshad
	mov	a,m
	ana	c	
	mov	m,a	
	out	miscout
	ret


; set up floppy DMA
; BC = buffer address
; E = low byte of count-1 (127 for single density sector)
s0848:	di	
	mvi	d,000h
	lda	041f5h
	mov	h,a
	rrc
	rrc
	rrc
	rrc
	inr	a	
	mov	l,a	
	in	dmactmp		; reads 0ffh if 8257
	ana	a
	jz	l0860

	mvi	a,0a5h
	out	dmamode
	mov	d,h	
l0860:	mvi	a,005h
	out	dmawsmr		; 8237 only, 8257 NOP
	mov	a,c
	out	dmac1a
	mov	a,b	
	out	dmac1a
	mov	a,e	
	out	dmac1tc
	mov	a,d	
	out	dmac1tc
	jz	l0877

	mvi	a,0a7h
	out	dmamode
l0877:	mov	a,l	
	out	dmawmod
	mvi	a,001h
	out	dmawsmr
	ei
	ret


s0880:	in	fdcstat
	ral
	jc	s0880
	ret	


s0887:	call	s0880
	mov	a,c	
	out	fdccmd
	ret


; build map of logical sector number (001h to 01ah) to physical sector number
; on entry, C is nonzero if sectseq bit was set in IOPB channel word
s088e:	mvi	b,maxsect

	lxi	h,04232h	; end of table of two-byte logical sect num
	lxi	d,04266h	; end of table of four-byte phys sect info

	push	b		; save pointers for use in second pass
	push	d

l0898:	mov	a,m
	stax	d
	dcx	h	
	dcx	h
	dcx	d
	dcx	d
	dcx	d
	dcx	d
	dcr	b	
	jnz	l0898

	pop	h		; restore pointers for second pass
	pop	b

	mov	a,c		; was the sectseq bit set?
	ana	a
	jnz	l08b4		; no

; set up remap for format
l08ab:	mov	m,b	
	dcx	h
	dcx	h
	dcx	h
	dcx	h
	dcr	b
	jnz	l08ab

l08b4:	lxi	h,04200h
	mvi	b,maxsect
	lda	041fbh
	mvi	c,000h
l08be:	mov	m,a
	inx	h
	mov	m,c
	inx	h	
	inx	h	
	mov	m,c
	inx	h	
	dcr	b	
	jnz	l08be
	ret	


s08ca:	call	s0880
	mvi	a,035h
	out	fdccmd
	mvi	e,4	; param byte count
s08d3:	in	fdcstat
	ani	020h
	jnz	s08d3

	ldax	b	; BC = pointer to param bytes
	inx	b
	out	fdcparm
	dcr	e
	jnz	s08d3
	ret


; cmd 00e - unknown
cmd0e:	mov	a,c	
	cpi	04eh
	lxi	b,00002h
	lxi	h,05f38h
	jz	s096a

	push	psw
	call	s098d
	pop	psw
	cpi	02eh
	jz	s096a

	mov	a,l
	mov	l,h
	mov	h,a
	call	s1006
	mov	d,h	
	mov	e,l	
	dad	b
	dcx	h	
	mov	a,h	
	sui	05ah
	mov	h,a	
	inx	h
	xchg
	jc	s096a

	push	d
	sub	a	
	sub	l	
	mov	c,a	
	mvi	a,05ah
	sbb	h	
	mov	b,a	
	call	s096a
	pop	b	
	lxi	h,scrbeg
	jmp	s096a


; cmd 00d - load memory from master
cmd0d:	lda	05af4h
	cpi	024h
	jnz	badcmd

	call	s098d	; get address and byte count from master
	jmp	l0932


; transfer a number of data blocks from master
; DE = buffer address
s092c:	out	iocbusy
	lxi	b,00d00h
	xchg

; transfer a number of bytes from master
l0932:	mov	a,b	; if byte count is zero, return
	ora	c	
	rz

	dcx	b
	inr	b	
	inr	c

; The first time through this loop may transfer less than 256 bytes,
; but all subsequent iterations will transfer 256 bytes
	lxi	d,0080ah	; load dbbstat masks
l093b:	call	s094a		; transfer C bytes
	dcr	b		; decrement block count
	jnz	l093b

	ret


l0943:	in	dbbin
	cma
	mov	m,a	
	inx	h
	dcr	c	
	rz	

; transfer 1 to 256 bytes from master
; HL = address
; E = dbbstat mask
; D = required dbbstat bit values
; C = count (0 will transfer 256 bytes)
s094a:	in	dbbstat
	ana	e	
	cmp	d	
	jz	l0943

	in	dbbstat
	ana	e
	cmp	d
	jz	l0943

	in	dbbstat
	ana	e
	jnz	s094a

	ret	


s095f:	xchg
	out	iocbusy
	sub	a	
	add	c	
	rar
	mov	b,a	
	mvi	a,000h
	rar
	mov	c,a	

s096a:	mov	a,b	
	ora	c	
	rz
	
	dcx	b
	inr	b	
	inr	c
	jmp	l0979

l0973:	in	dbbstat
	rrc	
	jnc	l0973

l0979:	mov	a,m
	cma
	out	dbbout
	inx	h
	dcr	c	
	jnz	l0973

	dcr	b	
	jnz	l0973

l0986:	in	dbbstat
	rrc
	jnc	l0986

	ret	


; receive mem addr, count from master
; each two-bytes, little endian
s098d:	call	mget1d
	mov	l,a	
	call	mget1d
	mov	h,a	
	call	mget1d
	mov	c,a	
	call	mget1d
	mov	b,a	
	ret


d099e:	dw	00000h		; 000h cpacify
	dw	ereset		; 001h cereset
	dw	systat		; 002h csystat
	dw	dstat		; 003h cdstat
	dw	srqdak		; 004h csrqdak
	dw	srqack		; 005h csrqack
	dw	srq		; 006h csrq
	dw	decho		; 007h cdecho
	dw	csmem		; 008h ccsmem
	dw	tram		; 009h ctram
	dw	sint		; 00ah csint
	dw	badcmd		; 00bh
	dw	badcmd		; 00ch
	dw	cmd0d		; 00dh ?
	dw	cmd0e		; 00eh ?
	dw	cmd0f		; 00fh ?
	dw	crtc		; 010h ccrtc
	dw	crts		; 011h ccrts
	dw	keyc		; 012h ckeyc
	dw	kstc		; 013h ckstc
	dw	badcmd		; 014h
	dw	wpbc		; 015h cwpbc
	dw	wpbcc		; 016h cwpbcc
	dw	wdbc		; 017h cwdbc
	dw	badcmd		; 018h
	dw	rdbc		; 019h crdbc
	dw	badcmd		; 01ah
	dw	rrsts		; 01bh crrsts
	dw	rdsts		; 01ch crdsts
	dw	badcmd		; 01dh
	dw	badcmd		; 01eh
	dw	badcmd		; 01fh


; invalid command
badcmd:	lda	systatb
	ori	illcmd
	sta 	systatb
	ret


s09e7:	in	kbdstat
	sta	04103h
	rar
	jnc	l09f9

	in	kbddat
	mov	c,a	
	call	05ff5h
	call	s1012
l09f9:	ret


; cmd 006h - Tests ability of IOC to forward an interrupt request to the master.
; pulse miscout.unkout4 low very briefly
srq:	lda	moshad
	ani	0fdh
	out	miscout
	lda	moshad
	out	miscout
	ret	


xs080f:	lda	041efh
	ani	007h
	lxi	h,041f2h
	ora	m
	mov	m,a	
	call	srq
	lxi	h,041eeh
	mvi	m,0ffh
	ret


s0a1a:	lda	041edh
	ani	080h
	cpi	000h
	jz	l0a2c

	lda	041efh
	ori	004h
	sta	041efh
l0a2c:	ret


; cmd 016h - Enable input from master of subsequent IOPB byte.
; (note that wpbc actually calls this for the Channel Word byte.)
wpbcc:	mvi	a,005h		; check if full IOPB already received
	lxi	h,iopbcnt
	cmp	m
	jc	l0a56		; yes, error

	lxi	b,041ffh
	call	mget1d
	lhld	iopbcnt
	mvi	h,000h
	lxi	b,iopb
	dad	b
	mov	m,a	
	lxi	h,iopbcnt
	inr	m
	mov	a,m
	cpi	005h
	jnz	l0a53

	call	xs0803
l0a53:	call	s0a1a
l0a56:	ret


; cmd 002h - Returns subsystem status byte to master
; bit 7 - device error
; bit 6 - illegal command
; bit 5 - illegal data transfer
; bit 4 - illegal interrupt mask
; bits 3..0 - reserved
systat:	lda	041f4h
	lxi	h,041f3h
	ana	m
	lxi	h,041ffh
	ana	m	
	ani	0f0h
	cpi	000h
	jz	l0a71

	lda	systatb
	ori	deverr
	sta	systatb

l0a71:	lda	systatb		; output systat byte
	cma			; (hw negative logic)
	out	dbbout

	lxi	h,systatb	; clear systat byte
	mvi	m,000h

	mvi	a,000h
	out	clrcd
	ret


; cmd 003h - returns device status byte to master
; bit 7 - diskette error
; bit 6 - keyboard error
; bit 5 - CRT error
; bits 4..3 reserved
; bit 2 - diskette interrupt
; bit 1 - keyboard interrupt
; bit 0 - CRT interrupt
dstat:	lda	041f3h
	ani	0f0h
	cpi	000h
	jz	l0a93

	lda	041f2h
	ori	020h
	sta	041f2h
l0a93:	lda	041f4h
	ani	0f0h
	cpi	000h
	jz	l0aa5

	lda	041f2h
	ori	040h
	sta	041f2h
l0aa5:	lda	041ffh
	ani	0f0h
	cpi	000h
	jz	l0ab7

	lda	041f2h
	ori	080h
	sta	041f2h
l0ab7:	lda	041f2h
	cma
	out	dbbout
	lxi	h,041f2h
	mvi	m,000h
	mvi	a,000h
	out	clrcd
	ret


; cmd 004h - Enables input of device interrupt acknowledge mask from master.
; bits 7..3 reserved
; bit 2 - diskette interrupt reset
; bit 1 - keyboard interrupt reset
; bit 0 - CRT interrupt reset
srqdak:	lxi	b,systatb
	call	mget1d
	sta	04101h
	lda	04101h
	ani	007h
	push	psw
	lda	041efh
	cma
	pop	b
	mov	c,b	
	ana	c
	cpi	000h
	jz	l0aed

	lda	systatb
	ori	illmsk
	sta	systatb
	jmp	l0b10


l0aed:	lda	04101h
	cma
	ani	007h
	sta	04103h
	lxi	h,041efh
	ana	m
	mov	m,a
	lda	04103h
	add	a
	add	a
	add	a
	add	a
	lxi	h,04103h
	ora	m
	lxi	h,041f2h
	ana	m
	mov	m,a	
	lxi	h,041eeh
	mvi	m,000h
l0b10:	ret


; cmd 005h - Clears IOC subsystem interrupt request
srqack:	lxi	h,041efh
	mvi	m,000h
	lxi	h,041f2h
	mvi	m,000h
	lxi	h,041eeh
	mvi	m,000h
	ret


; cmd 007h - Tests ability of IOC to echo data byte sent by master
decho:	lxi	b,systatb
	call	mget1d
	sta	04103h
	lda	041edh
	cpi	027h
	jnz	l0b37

	lxi	h,04103h
	mvi	m,0edh
l0b37:	lda	04103h
	out	dbbout
	mvi	a,000h
	out	clrcd
	ret


; cmd 008h - Requests IOC to checksum on-board ROM. Returns pass/fail.
csmem:	mvi	c,000h
	call	romt2c	; same as romt2k, but with arg in C
	out	dbbout
	ret


; cmd 009h - Requests IOC to test on-board RAM. Returns pass/fail.
tram:	lxi	d,04200h
	mvi	c,001h
	call	s000b
	out	dbbout
	ret


; cmd 00ah - Enables specified device interrupt from IOC.
; bits 7..3 reserved
; bit 2 - diskette interrupt enable
; bit 1 - keyboard interrupt enable
; bit 0 - CRT interrupt enable
sint:	lxi	b,systatb
	call	mget1d
	ani	007h
	sta	041f0h
	ret


; cmd 010h - Requests data byte output to the CRT monitor.
crtc:	lxi	b,041f3h
	call	mget1d
	mov	c,a	
	call	05ff5h
	lda	041efh
	ori	001h
	sta	041efh
	ret


; cmd 011h - Returns CRT status byte to master.
; bit 7 - reserved
; bit 6 - illegal status
; bit 5 - illegal data
; bits 4..1 - reserved
; bit 0 - CRT present
crts:	lda	041edh
	ani	080h
	cpi	000h
	jz	l0b85

	lda	041f3h
	ori	040h
	sta	041f3h
l0b85:	lda	041f3h
	ori	001h
	cma
	out	dbbout
	lxi	h,041f3h
	mvi	m,000h
	ret


; cmd 015h - Enables input from master of IOPB Channel Word byte.
wpbc:	lxi	h,iopbcnt
	mvi	m,000h
	mvi	c,0f7h
	call	s083f
	call	wpbcc
	ret


; cmd 017h - Enables input of diskette write bytes from master.
; The first byte transferred from the master is the number of 128-byte
; records to follow.
wdbc:	lxi	b,041ffh
	call	mget1d
	mov	c,a		; block count
	lxi	d,04200h	; buffer address
	call	s092c		; transfer data blocks from master
	call	s0a1a
	ret


; cmd 019h - Enables input of diskette read bytes to master.
rdbc:	mvi	c,008h
	call	s0834
	lhld	041fah
	mov	c,l	
	lxi	d,04200h
	call	s095f
	call	s0a1a
	ret


; cmd 01bh - Returns disk result byte to master.
rrsts:	call	xs0809
	cma
	out	dbbout
	ret


; cmd 01ch - Returns diskette device status byte to master.
rdsts:	call	xs0806
	lda	041f0h
	ani	004h
	cpi	000h
	jz	l0be1
	
	lda	041efh
	ori	004h
	sta	041efh
l0be1:	lda	041edh
	ani	080h
	cpi	000h
	jz	l0bf3

	lda	041ffh
	ori	040h
	sta	041ffh
l0bf3:	lda	041ffh
	cma
	out	dbbout
	lda	041ffh
	ani	00bh
	sta	041ffh
	ret	


s0c02:	call	s1800
	call	s1012
	ei	
	lda	041fdh
	rar	
	jnc	l0c4b
	lda	041f0h
	ani	004h
	cpi	000h
	jz	l0c4b

	lda	041efh
	ani	004h
	cpi	000h
	jnz	l0c4b
	
	in	fdcstat
	cma
	ani	080h
	cpi	000h
	jz	l0c4b

	lda	041ffh
	ani	004h
	sta	041ffh
	lxi	h,041fdh
	mvi	m,000h
	in	fdcrslt
	sta	041f6h
	inx	h
	mvi	m,0ffh
	lda	041efh
	ori	004h
	sta	041efh
l0c4b:	lda	041eeh
	rar	
	jc	l0c7b

	lxi	h,05f34h
	lda	05f35h
	cmp	m
	jz	l0c5f

	call	s1815
l0c5f:	lda	041efh
	ani	007h
	cpi	000h
	jz	l0c7b

	lda	041efh
	ani	002h
	cpi	000h
	jz	l0c78

	lxi	h,041ech
	mvi	m,000h
l0c78:	call	xs080f
l0c7b:	in	kbdstat
	ani	005h
	cpi	005h
	jnz	l0c87

	call	s180f
l0c87:	in	miscin
	ani	kbpres+localmd
	cpi	kbpres+localmd
	jnz	l0c96

	call	s09e7
	jmp	l0c87

l0c96:	in	miscin
	ani	kbpres
	cpi	kbpres
	jnz	l0cae

l0c9f:	in	kbdstat
	ani	004h
	cpi	000h
	jnz	l0cae

	call	s09e7
	jmp	l0c9f

l0cae:	mvi	a,000h
	out	iocbusy
	ret	


; cmd 001h - Resets device-generated error (not used by standard devices).
ereset:	lxi	h,04080h
	sphl
	call	s0c02
	call	s181b
l0cbd:	lxi	h,04080h
	sphl
	call	s0c02
	jmp	l0cbd

;0cc7 XXX unreachable?
	ret	


d0cc8:	db	021h,01ah,02eh,020h

d0ccc:	db	000h,004h,004h,000h,004h,010h,002h,002h
	db	080h,020h,004h,040h,004h,000h,000h,000h

d0cdc:	db	00dh,009h,009h,03ch

d0ce0:	db	010h,0ffh,0ffh,000h

d0ce4:	db	017h,000h


s0ce6:	call	s0880
	in	fdcrslt
	ret	


s0cec:	lxi	h,0410dh
	mov	m,c	
	lxi	h,04200h
	shld	0410bh
	lda	041fah
	cpi	001h
	jnz	l0d07

	call	s0d50
	lxi	h,041fdh
	mvi	m,0ffh
	ret	

l0d07:	lda	0410dh
	ori	001h
	sta	0410dh
	lxi	h,0410eh
	mvi	m,001h
l0d14:	lda	041fah
	lxi	h,0410eh
	cmp	m
	jc	l0d4f
	
	call	s0d50
	call	s0ce6
	sta	041f6h
	lxi	h,041fch
	inr	m
	lxi	d,00080h
	lhld	0410bh
	dad	d
	shld	0410bh
	lxi	h,041feh
	mvi	m,0ffh
	mvi	a,004h
	inx	h
	ora	m
	mov	m,a
	lda	041f6h
	cpi	000h
	jz	l0d48
	ret	

l0d48:	lxi	h,0410eh
	inr	m
	jnz	l0d14

l0d4f:	ret	


s0d50:	lhld	0410bh
	mov	b,h	
	mov	c,l	
	mvi	e,07fh
	call	s0848
	lda	041fbh
	sta	04104h
	lda	041fch
	sta	04105h
	lxi	h,04106h
	mvi	m,001h
	lhld	0410dh
	mov	c,l	
	call	s0887
	mvi	e,003h
	lxi	b,04104h
	call	s08d3
	ret


s0d7b:	lda	iopb+iopbocw	; get channel word
	ani	sectseq
	mov	c,a	
	call	s088e

	mvi	e,067h
	lxi	b,04200h
	call	s0848
	mvi	c,063h
	call	s0887
	lxi	h,041fdh
	mvi	m,0ffh
	mvi	e,001h
	lxi	b,041fbh
	call	s08d3
	mvi	e,004h
	lxi	b,d0cc8
	call	s08d3
	ret


s0da7:	lxi	h,0410fh
	mov	m,c
	mvi	c,069h
	call	s0887
	lxi	h,041fdh
	mvi	m,0ffh
	mvi	e,001h
	lxi	b,0410fh
	call	s08d3
	ret


s0dbe:	lxi	h,04110h
	mov	m,c	
	lda	04110h
	ori	040h
	mov	c,a	
	call	s0887
	call	s0ce6
	sta	0410ah
	lda	0410ah
	ani	004h
	cpi	000h
	jnz	l0de8

	lhld	04110h
	mov	c,l	
	call	s0887
	call	s0ce6
	sta	04109h
l0de8:	ret	


xs0803:	call	s083d
	lxi	h,041f5h
	mvi	m,080h
	lda	iopb+iopboin	; get diskette instruction byte
	ani	007h
	mov	c,a	
	mvi	b,000h
	lxi	h,d0e59
	dad	b
	dad	b
	mov	e,m
	inx	h
	mov	d,m
	xchg
	pchl


l0e03:	lda	041ffh
	ori	004h
	sta	041ffh
	jmp	l0e69

l0e0e:	lhld	041fbh
	mov	c,l	
	call	s0da7
	jmp	l0e69

l0e18:	call	s082f
	call	s0d7b
	jmp	l0e69

l0e21:	mvi	c,000h
	call	s0da7
	jmp	l0e69

l0e29:	lxi	h,041f5h
	mvi	m,040h
	mvi	c,052h
	call	s0cec
	jmp	l0e69

l0e36:	lxi	h,041f5h
	mvi	m,000h
	mvi	c,05eh
	call	s0cec
	jmp	l0e69

l0e43:	call	s082f
	mvi	c,04ah
	call	s0cec
	jmp	l0e69
	
l0e4e:	call	s082f
	mvi	c,04eh
	call	s0cec
	jmp	l0e69


d0e59:	dw	l0e03
	dw	l0e0e
	dw	l0e18
	dw	l0e21
	dw	l0e29
	dw	l0e36
	dw	l0e43
	dw	l0e4e

l0e69:	ret


s0e6a:	mvi	c,02ch
	call	s0dbe
	lda	041ffh
	ani	0feh
	push	psw
	lda	0410ah
	ani	004h
	ani	0feh
	rar
	rar
	pop	b
	mov	c,b	
	ora	c	
	sta	041ffh
	ret


xs0806:	in	miscin
	ani	flppres
	cpi	000h
	jnz	l0e97
	lda	041ffh
	ani	0f7h
	sta	041ffh
	ret	


l0e97:	lda	041ffh
	ori	008h
	sta	041ffh
	lda	041fdh
	cpi	000h
	jnz	l0eab

	call	s0e6a
	ret	

l0eab:	lda	041ffh
	ani	0fbh
	push	psw	
	in	fdcstat
	cma
	ani	080h
	rlc
	rlc	
	rlc	
	pop	b
	mov	c,b	
	ora	c	
	sta	041ffh
	lda	041ffh
	ani	004h
	cpi	000h
	jz	l0edc

	lxi	h,041fdh
	mvi	m,000h
	call	s0ce6
	sta	041f6h
	lxi	h,041feh
	mvi	m,0ffh
	call	s0e6a
l0edc:	ret	


xs0809:	lda	041feh
	rar	
	jc	00ee9h

	lxi	h,041f6h
	mvi	m,000h
l0ee9:	lxi	h,041feh
	mvi	m,000h
	dcx	h
	mov	a,m
	rar
	jnc	l0efa

	call	s0ce6
	sta	041f6h
l0efa:	lxi	h,041fdh
	mvi	m,000h
	lda	041f6h
	cpi	000h
	jnz	l0f0a

	mvi	a,000h
	ret	

l0f0a:	lda	041f6h
	ani	020h
	cpi	000h
	jz	l0f1c

	lxi	h,04111h
	mvi	m,001h
	jmp	00f21h

l0f1c:	lxi	h,04111h
	mvi	m,000h
l0f21:	lda	041f6h
	ani	01eh
	ora	a	
	rar
	mov	c,a	
	mvi	b,000h
	lxi	h,d0ccc
	dad	b
	lda	04111h
	ora	m
	ret


xs080c:	in	miscin
	ani	flppres
	cpi	000h
	jz	l0f5e

	mvi	a,001h
	out	fdcrst
	mvi	a,000h
	out	fdcrst
	lxi	b,d0cdc
	call	s08ca
	lxi	b,d0ce0
	call	s08ca
	mvi	c,03ah
	call	s0887
	mvi	e,002h
	lxi	b,d0ce4
	call	s08d3
l0f5e:	ret

	db	"CORP INTEL corp.1981-83"

	fillto	00ffeh,0ffh

; checksum
	dw	03933h
