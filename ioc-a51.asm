	cpu	8080

	include	ioc-io.inc
	include	ioc-flp.inc
	include ioc-mac.inc
	
; entry points in ROM 0

s000b	equ	0000bh	; RAM test
romt2c	equ	0002bh

; entry points in ROM 2

cblkm	equ	01003h	; cmd 00fh - block move data to CRT
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

	org	04000h
	ds	128
stack:

	org	04101h
r4101:	ds	1
iopbcnt	ds	1	; count of IOPB bytes received
r4103:	ds	1
r4104:	ds	1
r4105:	ds	1
r4106:	ds	1
	ds	1
	ds	1
r4109:	ds	1
r410a:	ds	1
r410b:	ds	2
r410d:	ds	1
r410e:	ds	1
r410f:	ds	1
r4110:	ds	1
r4111:	ds	1

	org	041ech
r41ec:	ds	1
r41ed:	ds	1
r41ee:	ds	1
r41ef:	ds	1
intena:	ds	1	; interrupt enables
systatb	ds	1
dstatb:	ds	1
crtstb:	ds	1	; CRT status byte
r41f4:	ds	1
r41f5:	ds	1
r41f6:	ds	1
moshad:	ds	1	; RAM shadow of miscout register
iopb:	ds	iopbsiz
r41fd:	ds	1
r41fe:	ds	1
dskstb:	ds	1	; diskette status byte

databf:	ds	26*128	; 04200h through 04f00h

crtrows	equ	25
crtcols	equ	80
crtsize	equ	crtrows*crtcols

	org	05230h
scrbeg:	ds	crtsize	; start of screen buffer
scrend:			; ends at 05a00h (last byte used 059ffh)

	org	05af4h
r5af4:	ds	1

	org	05ff5h
r5ff5:			; code, size unknown


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

; DSTAT bits
dskerr	equ	080h
kbderr	equ	040h
crterr	equ	020h
; bits 4..3 reserved
dskint	equ	004h
kbdint	equ	002h
crtint	equ	001h

; CRTS bits
crtils	equ	040h
crtild	equ	020h
crtprs	equ	001h

; diskette status byte
; bits 7, 4, 0 reserved
fdsils	equ 	040h	; illegal status
fdsild	equ	020h	; illegal data
fdsprs	equ	008h	; drive present
fdscmp	equ	004h	; operation complete
fdsrdy	equ	002h	; drive ready
fdsrs0	equ	001h	; reserved bit, unknown purpose


	org	00800h

l0800:	jmp	ereset
s0803:	jmp	xs0803
s0806:	jmp	xs0806
s0809:	jmp	xs0809
s080c:	jmp	xs080c
	jmp	xs080f		; XXX no external references?

d0812:	dw	d099e


; Externally referenced
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
	lda	r41f5
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


; build ID fields to format a track
; on entry, C is nonzero if sectseq bit was set in IOPB channel word
fbldid:	mvi	b,maxsect

; Assuming sectseq bit was set, the sector numbers are provided as the
; first byte of each of 26 two-byte mapping table entries transferred from
; the master.
; Move them into the third byte of each ID field entry.
; Both the tables start at databf, and dest entries take more room than src,
; so start from the end of the buffers and work toward the beginning.
	lxi	h,databf+2*maxsect-2	; end of table of two-byte logical sect num
	lxi	d,databf+4*maxsect-2	; end of table of four-byte phys sect info

	push	b		; save pointers for use in second pass
	push	d

l0898:	mov	a,m		; copy sector number
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

	mov	a,c		; was special sector ordering requested
	ana	a
	jnz	l08b4		; yes

; Special sector ordering not requested, use sequential sector numbers
; from 1 to 26. Since HL is pointing to the sector number field of the
; last entry, work backwards, counting down to 1
l08ab:	mov	m,b
	dcx	h
	dcx	h
	dcx	h
	dcx	h
	dcr	b
	jnz	l08ab

; Now fill in track, head, and sector size (first, second, and fourth bytes
; of each entry).
l08b4:	lxi	h,databf
	mvi	b,maxsect	; B = loop counter
	lda	iopb+iopbotk	; A = IOPB track number
	mvi	c,000h		; C = 0 (constant)

l08be:	mov	m,a	; track
	inx	h

	mov	m,c	; head = 0
	inx	h	

	inx	h	; skip sector, already hav eit

	mov	m,c	; sector size = 0
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


; cmd 00eh - unknown
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


; cmd 00dh - load memory from master
; Only allowed if RAM loc r5af4 contains 024h. But how can one set that?
cmd0d:	lda	r5af4
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


; IOC command dispatch table

; The basic set of IOC commands is documented in Intel's "Intellec
; Series II Microcomputer Development System Hardware Interface
; Manual", order number 9800555-03, dated July 1983, in chapter 4 "IOC
; I/O Interfaces".

; One additional command, 00fh, CRT block transfer, is documented in
; Intel's "Intellec Series II CRT and Keyboard Interface Manual",
; order number 122029-001, dated August 1982.  This is applicable to
; Series II MDS systems that have the IMDX 511 IOC Firmware Enhancement
; Kit, installation of which is documented in Intel's "iMDX 511 IOC
; Firmware Enhancement Kit Installation Instructions", order number
; 122014-002, dated May 1983.

; I have been unable to find any official documentation on commands
; 00dh and 00eh.

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
	dw	cblkm		; 00fh cblkm
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
	sta	r4103
	rar
	jnc	l09f9

	in	kbddat
	mov	c,a	
	call	r5ff5
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


xs080f:	lda	r41ef
	ani	007h
	lxi	h,dstatb
	ora	m
	mov	m,a	
	call	srq
	lxi	h,r41ee
	mvi	m,0ffh
	ret


s0a1a:	lda	r41ed
	ani	080h
	cpi	000h
	jz	l0a2c

	lda	r41ef
	ori	004h
	sta	r41ef
l0a2c:	ret


; cmd 016h - Enable input from master of subsequent IOPB byte.
; (note that wpbc actually calls this for the Channel Word byte.)
wpbcc:	mvi	a,005h		; check if full IOPB already received
	lxi	h,iopbcnt
	cmp	m
	jc	l0a56		; yes, error

	lxi	b,dskstb	; address in which to set illegal data flag
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

	call	xs0803		; issue FD command
l0a53:	call	s0a1a
l0a56:	ret


; cmd 002h - Returns subsystem status byte to master
; bit 7 - device error
; bit 6 - illegal command
; bit 5 - illegal data transfer
; bit 4 - illegal interrupt mask
; bits 3..0 - reserved
systat:	lda	r41f4
	lxi	h,crtstb
	ana	m
	lxi	h,dskstb
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
dstat:	lda	crtstb
	ani	0f0h
	cpi	000h
	jz	l0a93

	lda	dstatb
	ori	crterr
	sta	dstatb

l0a93:	lda	r41f4
	ani	0f0h
	cpi	000h
	jz	l0aa5

	lda	dstatb
	ori	kbderr
	sta	dstatb

l0aa5:	lda	dskstb
	ani	0f0h
	cpi	000h
	jz	l0ab7

	lda	dstatb
	ori	dskerr
	sta	dstatb

l0ab7:	lda	dstatb		; send DSTAT to master
	cma			; (hw negative logic)
	out	dbbout

	lxi	h,dstatb	; clear DSTAT
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
	sta	r4101
	lda	r4101		; superfluous!
	ani	007h
	push	psw
	lda	r41ef
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

l0aed:	lda	r4101
	cma
	ani	007h
	sta	r4103
	lxi	h,r41ef
	ana	m
	mov	m,a
	lda	r4103
	add	a
	add	a
	add	a
	add	a
	lxi	h,r4103
	ora	m
	lxi	h,dstatb
	ana	m
	mov	m,a	
	lxi	h,r41ee
	mvi	m,000h
l0b10:	ret


; cmd 005h - Clears IOC subsystem interrupt request
srqack:	lxi	h,r41ef
	mvi	m,000h
	lxi	h,dstatb
	mvi	m,000h
	lxi	h,r41ee
	mvi	m,000h
	ret


; cmd 007h - Tests ability of IOC to echo data byte sent by master
decho:	lxi	b,systatb	; get data byte from master
	call	mget1d
	sta	r4103

	lda	r41ed
	cpi	027h
	jnz	l0b37

	lxi	h,r4103
	mvi	m,0edh

l0b37:	lda	r4103		; return data byte to master
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
tram:	lxi	d,databf
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
	sta	intena
	ret


; cmd 010h - Requests data byte output to the CRT monitor.
crtc:	lxi	b,crtstb
	call	mget1d
	mov	c,a	
	call	r5ff5
	lda	r41ef
	ori	001h
	sta	r41ef
	ret


; cmd 011h - Returns CRT status byte to master.
; bit 7 - reserved
; bit 6 - illegal status
; bit 5 - illegal data
; bits 4..1 - reserved
; bit 0 - CRT present
crts:	lda	r41ed		; was completion interrupt requested
	ani	080h
	cpi	000h
	jz	l0b85

	lda	crtstb		; yes, illegal
	ori	crtils
	sta	crtstb

l0b85:	lda	crtstb
	ori	crtprs
	cma			; (hw negative logic)
	out	dbbout

	lxi	h,crtstb	; clear CRT status
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
wdbc:	lxi	b,dskstb	; address in which to set illegal data flag
	call	mget1d
	mov	c,a		; block count
	lxi	d,databf	; buffer address
	call	s092c		; transfer data blocks from master
	call	s0a1a
	ret


; cmd 019h - Enables input of diskette read bytes to master.
rdbc:	mvi	c,008h
	call	s0834
	lhld	iopb+iopbosc	; get sector count in L
	mov	c,l	
	lxi	d,databf
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
	lda	intena
	ani	004h
	cpi	000h
	jz	l0be1
	
	lda	r41ef
	ori	004h
	sta	r41ef
l0be1:	lda	r41ed
	ani	080h
	cpi	000h
	jz	l0bf3

	lda	dskstb
	ori	fdsils		; illegal status
	sta	dskstb

l0bf3:	lda	dskstb		; output disk status byte
	cma			; (hw negative logic)
	out	dbbout

	lda	dskstb
	ani	fdsprs+fdsrdy+fdsrs0
	sta	dskstb

	ret	


s0c02:	call	s1800
	call	s1012
	ei	
	lda	r41fd
	rar	
	jnc	l0c4b
	lda	intena
	ani	004h
	cpi	000h
	jz	l0c4b

	lda	r41ef
	ani	004h
	cpi	000h
	jnz	l0c4b
	
	in	fdcstat
	cma
	ani	080h
	cpi	000h
	jz	l0c4b

	lda	dskstb		; clear disk status byte except operation complete
	ani	fdscmp
	sta	dskstb

	lxi	h,r41fd
	mvi	m,000h
	in	fdcrslt
	sta	r41f6
	inx	h
	mvi	m,0ffh
	lda	r41ef
	ori	004h
	sta	r41ef
l0c4b:	lda	r41ee
	rar	
	jc	l0c7b

	lxi	h,05f34h
	lda	05f35h
	cmp	m
	jz	l0c5f

	call	s1815
l0c5f:	lda	r41ef
	ani	007h
	cpi	000h
	jz	l0c7b

	lda	r41ef
	ani	002h
	cpi	000h
	jz	l0c78

	lxi	h,r41ec
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
ereset:	lxi	h,stack
	sphl
	call	s0c02
	call	s181b
l0cbd:	lxi	h,stack
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


s0cec:	lxi	h,r410d
	mov	m,c	
	lxi	h,databf
	shld	r410b
	lda	iopb+iopbosc	; sector count
	cpi	001h
	jnz	l0d07

	call	s0d50
	lxi	h,r41fd
	mvi	m,0ffh
	ret

l0d07:	lda	r410d
	ori	001h
	sta	r410d
	lxi	h,r410e
	mvi	m,001h
l0d14:	lda	iopb+iopbosc	; sector count
	lxi	h,r410e
	cmp	m
	jc	l0d4f
	
	call	s0d50
	call	s0ce6
	sta	r41f6
	lxi	h,iopb+iopbose	; sector number
	inr	m
	lxi	d,00080h
	lhld	r410b
	dad	d
	shld	r410b
	lxi	h,r41fe
	mvi	m,0ffh
	mvi	a,004h
	inx	h
	ora	m
	mov	m,a
	lda	r41f6
	cpi	000h
	jz	l0d48
	ret	

l0d48:	lxi	h,r410e
	inr	m
	jnz	l0d14

l0d4f:	ret	


s0d50:	lhld	r410b
	mov	b,h	
	mov	c,l	
	mvi	e,07fh
	call	s0848
	lda	iopb+iopbotk	; track
	sta	r4104
	lda	iopb+iopbose	; sector
	sta	r4105
	lxi	h,r4106
	mvi	m,001h
	lhld	r410d
	mov	c,l	
	call	s0887
	mvi	e,003h
	lxi	b,r4104
	call	s08d3
	ret


s0d7b:	lda	iopb+iopbocw	; get channel word
	ani	sectseq
	mov	c,a	
	call	fbldid		; build ID fields

	mvi	e,067h
	lxi	b,databf
	call	s0848
	mvi	c,063h
	call	s0887
	lxi	h,r41fd
	mvi	m,0ffh
	mvi	e,001h
	lxi	b,iopb+iopbotk
	call	s08d3
	mvi	e,004h
	lxi	b,d0cc8
	call	s08d3
	ret


s0da7:	lxi	h,r410f
	mov	m,c
	mvi	c,069h
	call	s0887
	lxi	h,r41fd
	mvi	m,0ffh
	mvi	e,001h
	lxi	b,r410f
	call	s08d3
	ret


s0dbe:	lxi	h,r4110
	mov	m,c	
	lda	r4110
	ori	040h
	mov	c,a	
	call	s0887
	call	s0ce6
	sta	r410a
	lda	r410a
	ani	004h
	cpi	000h
	jnz	l0de8

	lhld	r4110
	mov	c,l	
	call	s0887
	call	s0ce6
	sta	r4109
l0de8:	ret	


; issue FD command
xs0803:	call	s083d
	lxi	h,r41f5
	mvi	m,080h

	lda	iopb+iopboin	; get diskette instruction byte
	ani	007h		; mask command number
	mov	c,a		; move command number into BC
	mvi	b,000h
	lxi	h,d0e59
	dad	b		; add 2*command number 
	dad	b
	mov	e,m		; get handler addr into DE
	inx	h
	mov	d,m
	xchg			; jump to handler
	pchl


; FD no operation command
fdnoop:	lda	dskstb		; set diskette status operation complete
	ori	fdscmp
	sta	dskstb

	jmp	l0e69

; FD seek command
fdseek:	lhld	iopb+iopbotk
	mov	c,l	
	call	s0da7
	jmp	l0e69

; FD format track command
fmfmt:	call	s082f
	call	s0d7b
	jmp	l0e69

; FD recalibrate command
fdrec:	mvi	c,000h
	call	s0da7
	jmp	l0e69

; FD read data command
fdread:	lxi	h,r41f5
	mvi	m,040h
	mvi	c,052h
	call	s0cec
	jmp	l0e69

; FD verify CRC command
fdver:	lxi	h,r41f5
	mvi	m,000h
	mvi	c,05eh
	call	s0cec
	jmp	l0e69

; FD write (normal data) command
fdwrt:	call	s082f
	mvi	c,04ah
	call	s0cec
	jmp	l0e69
	
; FD write deleted data command
fdwrtd:	call	s082f
	mvi	c,04eh
	call	s0cec
	jmp	l0e69


d0e59:	dw	fdnoop	; no operation
	dw	fdseek	; seek
	dw	fmfmt	; format track
	dw	fdrec	; recalibrate
	dw	fdread	; read data
	dw	fdver	; verify CRC
	dw	fdwrt	; write data
	dw	fdwrtd	; write deleted data

l0e69:	ret


s0e6a:	mvi	c,02ch
	call	s0dbe

	lda	dskstb		; put disk status byte, less reserved bit 0, on stack
	ani	0feh
	push	psw

	lda	r410a
	ani	004h
	ani	0feh		; superfluous!
	rar
	rar

	pop	b		; get back disk status byte and or into acc
	mov	c,b	
	ora	c		; set flags
	sta	dskstb
	ret


xs0806:	in	miscin
	ani	flppres
	cpi	000h
	jnz	l0e97
	lda	dskstb
	ani	0f7h
	sta	dskstb
	ret	


l0e97:	lda	dskstb
	ori	008h
	sta	dskstb
	lda	r41fd
	cpi	000h
	jnz	l0eab

	call	s0e6a
	ret	

l0eab:	lda	dskstb
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
	sta	dskstb
	lda	dskstb
	ani	004h
	cpi	000h
	jz	l0edc

	lxi	h,r41fd
	mvi	m,000h
	call	s0ce6
	sta	r41f6
	lxi	h,r41fe
	mvi	m,0ffh
	call	s0e6a
l0edc:	ret	


xs0809:	lda	r41fe
	rar	
	jc	00ee9h

	lxi	h,r41f6
	mvi	m,000h
l0ee9:	lxi	h,r41fe
	mvi	m,000h
	dcx	h
	mov	a,m
	rar
	jnc	l0efa

	call	s0ce6
	sta	r41f6
l0efa:	lxi	h,r41fd
	mvi	m,000h
	lda	r41f6
	cpi	000h
	jnz	l0f0a

	mvi	a,000h
	ret	

l0f0a:	lda	r41f6
	ani	020h
	cpi	000h
	jz	l0f1c

	lxi	h,r4111
	mvi	m,001h
	jmp	00f21h

l0f1c:	lxi	h,r4111
	mvi	m,000h
l0f21:	lda	r41f6
	ani	01eh
	ora	a	
	rar
	mov	c,a	
	mvi	b,000h
	lxi	h,d0ccc
	dad	b
	lda	r4111
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
