	cpu	8080

	include	ioc-io.inc
	include	ioc-flp.inc
	include ioc-mac.inc

; entry points in ROM 0

s0005	equ	00005h
s001d	equ	0001dh
s0023	equ	00023h
s0025	equ	00025h
crtini	equ	00033h
l003b	equ	0003bh


; entry points in ROM 1

s080c	equ	0080ch
d0812	equ	00812h
mget1d	equ	00814h


; entry points in ROM 3

s1803	equ	01803h	; copy C bytes from (HL) to (DE)
s1806	equ	01806h	; unpack sparse table
s180f	equ	0180fh
s1812	equ	01812h
s1818	equ	01818h


; RAM, 4000h..5fffh

rambase	equ	04000h

	org	rambase
cursor	ds	2	; pointer into screen buffer for cursor loc

	org	041eah
d41ea:	ds	2
d41ec:	ds	1	; not sure of size
	ds	7
d41f4:	ds	1
	ds	2
moshad	ds	1	; RAM shadow of miscout register

	org	04200h
databf:	ds	26*128	; 04200h through 04f00h

crtrows	equ	25
crtcols	equ	80
crtsize	equ	crtrows*crtcols

	org	05230h
scrbeg:	ds	crtsize	; start of screen buffer
scrend:			; ends at 05a00h (last byte used 059ffh)

	org	05a7eh
r5a7e:	ds	2
r5a80:	ds	2
r5a82:	ds	2

	org	05af0h
r5af0:	ds	1
r5af1:	ds	1
r5af2:	ds	1
	ds	2
crsrfmt	ds	1
	ds	1
r5af7:	ds	1
r5af8:	ds	1

r5b00	equ	05b00h

r5b20	equ	05b20h

r5b80	equ	05b80h

r5c00	equ	05c00h

r5c41	equ	05c41h

r5c61	equ	05c61h

r5c80	equ	05c80h

	org	05f00h
r5f00	ds	52

	org	05f34h
r5f34:	ds	1
	ds	1
r5f36:	ds	2
r5f38:	ds	1
r5f39:	ds	1
r5f3a:	ds	2
r5f3c:	ds	2
r5f3e:	ds	1
r5f3f:	ds	1
r5f40:	ds	1
r5f41:	ds	1
r5f42:	ds	1
r5f43:	ds	1
	ds	1
r5f45:	ds	2
r5f47:	ds	2
r5f49:	ds	2
r5f4b:	ds	2
	ds	3
r5f50:	ds	1

rst5	equ	05fb4h

r5fbe	equ	05fbeh
rst7	equ	05fc0h
r5fc1	equ	05fc1h
r5fc4	equ	05fc4h
r5fc6	equ	05fc6h
r5fc8	equ	05fc8h
r5fcc	equ	05fcch
r5fd0	equ	05fd0h
r5fd4	equ	05fd4h
r5fe0	equ	05fe0h
r5fe4	equ	05fe4h
r5fec	equ	05fech
r5fee	equ	05feeh

	org	05ff5h
r5ff5:	ds	2		; code
r5ff7:				; code, unknown size


	org	01000h

s1000:	jmp	xs1000
cblkm:	jmp	xcblkm
s1006:	jmp	xs1006
s1009:	jmp	xs1009
s100c:	jmp	xs100c
	jmp	00000h		; unreferenced?
s1012:	jmp	xs1012
	jmp	xs1015		; unreferenced?
	jmp	xs1018		; unreferenced?
	jmp	xs101b		; unreferenced?

	
xs1009:	lxi	d,databf
	mvi	a,000h
l1023:	push	psw
	mov	h,a
	mvi	l,000h
	call	xs1006
	call	copy80
	pop	psw
	inr	a
	cpi	019h
	jnz	l1023
	lhld	r5f38
	shld	r5f49
	call	s15d1
	sub	a
	call	s170b
	call	xs100c
	call	xs1018
	push	b

	lxi	h,databf	; copy 2000 byts from databf to screen
	lxi	d,scrbeg
	mvi	c,000h		; copy first 1024 bytes
	call	copy4c
	mvi	c,0f4h		; copy remaining 976 bytes
	call	copy4c

	sub	a	
	sta	r5f3e
	lhld	r5f49
	call	xs1015
	pop	b	
	jmp	r5ff5


xs1006:	push	d
	lda	r5f3e
	add	h
	xchg
	call	s171d
	mvi	d,000h
	dad	d
	pop	d
	ret


; cmd 00fh: block move of data to CRT
; bit 6 of command determines function of data bytes with MSB set:
;     0:  output (n-80h) blanks
;     1:  output an attribute character
; bit 5 of command determines destination
;     0:  coordinates
;     1:  current cursor location
; requires coordinates if bit 5 of command
xcblkm:	out	iocbusy

	mov	a,c	
	ani	040h
	push	psw

	mov	a,c		; was bit 5 set?
	ani	020h
	lhld	r5f38
	jnz	l1092		; no

	call	mget1d		; yes, get coordinates
	mov	b,a		; B = row
	call	mget1d
	mov	c,a		; C = col
	sub	a
	call	s157c
	lhld	r5f38

l1092:	call	s1127

bmnext:	call	bmrdch
l1098:	jz	l10d0
	jc	l10d6

	cpi	0ffh		; is data byte 0ffh, indicating done?
	jnz	l10ad		; no

	mvi	a,050h		; done
	sub	c
	sta	r5f38
	pop	psw
	jmp	l1503

l10ad:	cpi	0feh		; is data byte 0feh, escaping following byte?
	jnz	l10c1		; no

l10b2:	in	dbbstat		; get next byte
	ana	d
	jnz	l10b2
	in	dbbin
	xra	b
l10bb:	call	bmput
	jmp	l1098

l10c1:	mov	b,a
	pop	psw
	push	psw
	mov	a,b
	mvi	b,0ffh
	jnz	l10bb
	call	s1146
	jmp	bmnext

l10d0:	call	s110d
	jmp	bmnext

l10d6:	cpi	00ah		; is it a line feed?
	jnz	l10e4		; no

	mvi	a,050h
	sub	c	
	call	s111f
	jmp	bmnext

l10e4:	cpi	00dh		; is it a carriage return?
	jnz	l10bb		; no

	inr	b
	dad	b
	dcr	b
	mvi	c,0b0h
	dad	b
	mvi	c,050h
	jmp	bmnext


; block move: jump here once we've read a byte from master, to set flags appropriately
bmrgot:	in	dbbin
	xra	b		; test whether special handling is necessary
	rm	
	cmp	e	
	rc	


bmput:	mov	m,a
	inx	h
	dcr	c
	rz


; block move: get a byte from master
bmrdch:	in	dbbstat
	ana	d	
	jz	bmrgot
	in	dbbstat
	ana	d	
	jz	bmrgot
	jmp	bmrdch


s110d:	lhld	r5f38
	mvi	l,000h
	inr	h
	lda	r5af1
	dcr	a
	cmp	h
	jnc	s1127
	mov	h,l
	jmp	s1127

s111f:	lhld	r5f38
	mov	l,a
	inr	h
	call	s16e2

s1127:	shld	r5f38
	mov	e,l	
	lda	r5f3e
	add	h
	call	s171d
	mvi	d,000h
	dad	d
	mvi	a,050h
	sub	e
	mov	c,a
	mvi	b,0ffh
	mvi	e,00eh
	mvi	d,002h
	in	kbdstat
	rrc	
	cc	s180f
	ret	


s1146:	ani	07fh
	rz

	cmp	c
	jc	s115a

	sub	c
	push	psw
	mov	a,c
	call	s115a
	call	s110d
	pop	psw
	jmp	s1146


s115a:	push	b
	mov	b,a
	ani	007h
	mov	c,a
	lda	r5af7
	jz	l116b

l1165:	mov	m,a
	inx	h
	dcr	c
	jnz	l1165

l116b:	mov	c,a
	mov	a,b
	push	psw
	rrc
	rrc
	rrc
	ani	01fh
	cnz	s001d
	pop	psw
	pop	b
	sub	c
	cma
	inr	a
	mov	c,a
	ret


xs1000:	lhld	d0812
	shld	d41ea
	lxi	h,d41ec
	lxi	d,databf
	call	s0023
	sub	a
	out	iocbusy
	out	clrcd
	out	dbbout+1	; XXX why +1?
	in	dbbin
	call	s11bc

	in	dmactmp		; using 8237 or 8257?
	adi	0ffh
	sbb	a	
	ori	020h
	ani	0a3h
	out	dmamode
	ani	080h
	sta	r5f41
	call	s080c
	mvi	a,022h
	sta	moshad
	out	miscout
	in	miscin
	ani	kbpres
	rlc	
	rlc	
	sta	d41f4
	ret
	

s11bc:	lxi	h,r5f34
	lxi	d,r5f50
	call	s0023

	lxi	h,rcodi
	lxi	d,rst5
	mvi	c,rmclen
	call	s1803

	lxi	d,scrbeg
	mvi	a,0f2h
	stax	d
	lxi	b,00050h
	lxi	h,r5f00
	mvi	a,01ah
l11de:	mov	m,e	
	inx	h
	mov	m,d
	inx	h
	xchg
	dad	b
	xchg
	dcr	a
	jnz	l11de

	mvi	a,050h
	sta	r5f43
	in	dmactmp		; using 8237 or 8257?
	ana	a	
	jz	01206h

	mvi	a,0f8h
	sta	r5fc6
	sta	r5fee
	mvi	a,0a3h
	sta	r5fc4
	ori	004h
	sta	r5fec
l1206:	lxi	h,r5a80
	lxi	d,r5c80
	call	s0023
	call	s1812
	lxi	h,d1289
	lxi	d,r5af1
	mvi	c,00bh
	call	s1803
	call	s1245
	lxi	d,r5c41
	call	s1264
	lxi	d,r5c61
	call	s1264
	call	s126c
	call	s15d1
	sub	a	
	call	s170b
	lxi	h,scrend
	shld	d41ea
	xchg
	lhld	d0812
	mvi	c,040h
	jmp	s1803


s1245:	mvi	c,000h
	lxi	d,d1797
	lda	r5a82
	rrc	
	jc	l1256
	
	mvi	c,003h
	lxi	d,d178b
l1256:	push	d	
	lxi	h,r5b00
	lxi	d,r5b20
	call	s0025
	pop	d
	jmp	s1806


s1264:	lxi	h,d1771
	mvi	c,01ah
	jmp	s1803


s126c:	lxi	h,r5b00
	lxi	d,r5b80
	call	s127b
	lxi	h,r5c00
	lxi	d,r5c80

s127b:	mov	a,m
	ana	a	
	jnz	l1282

	mvi	a,009h
l1282:	stax	d
	inr	l	
	inr	e	
	jnz	s127b
	ret


d1289:	db	019h,0a0h,000h,000h,020h,014h,080h,023h
	db	0ffh,000h,045h


; following code is copied to RAM
rcodi:	jmp	l12df		; 05fb4h: rst5 handler

	mvi	a,006h		; 05fb7h: rst6 handler  mvi opcode
	sta	r5ff5

	pop	psw		; 05fbch
	jmp	00000h		; 05fbdh

	rst	5		; 05fc0h rst7 handler

; The following code updates the CRT DMA parameters, DMAC channel 2
; for the top part of the screen, and DMAC channel 3 for the bottom
; part.  The code is run from RAM so that the parameter values can
; be quickly loaded with immediate operands, which are changed
; by ROM routines that handle display scrolling.
	in	crtstat		; 05fc1h
	mvi	a,00ch		; 05fc3h
	out	dmawamr		; 05fc5h

	mvi	a,scrbeg&0ffh			; 05fc7h
	out	dmac2a				; 05fc9h
	mvi	a,scrbeg>>8			; 05fcbh
	out	dmac2a				; 05fcdh
	mvi	a,(crtsize-1)&0ffh		; 05fcfh
	out	dmac2tc				; 05fc1h
	mvi	a,080h + ((crtsize-1)>>8)	; 05fd3h
	out	dmac2tc				; 05fd5h

	mvi	a,scrbeg&0ffh			; 05fd7h
	out	dmac3a				; 05fd9h
	mvi	a,scrbeg>>8			; 05fdbh
	out	dmac3a				; 05fddh
	mvi	a,(crtsize-1)&0ffh		; 05fdfh
	out	dmac3tc				; 05fe1h
	mvi	a,080h + ((crtsize-1)>>8)	; 05fe3h
	out	dmac3tc				; 05fe5h

	mvi	a,00ah				; 05fe7h
	out	dmawmod				; 05fe9h
	mvi	a,00bh				; 05febh
	out	dmawmod				; 05fedh
	sub	a				; 05fefh
	out	dmawamr				; 05ff0h
	pop	psw				; 05ff1h
	ei					; 05ff2h
	ret					; 05ff3h

	mvi	b,05bh				; 05ff4h
	ldax	b				; 05ff6h
	ana	a				; 05ff7h
	jz	l144c				; 05ff8h
	jmp	l1432				; 05ffbh
rmclen	equ	$-rcodi



l12df:	inx	sp
	inx	sp
	push	psw
	mvi	a,0f5h
	sta	rst7
	push	h
	call	s171a
	mov	a,l	
	sta	r5fc8
	cma	
	sta	r5fd0
	mov	a,h	
	sta	r5fcc
	lda	r5f41
	adi	059h
	sub	h	
	sta	r5fd4
	mvi	a,09fh
	add	l	
	sta	r5fe0
	lda	r5f41
	adc	h	
	adi	0b5h
	sta	r5fe4
	pop	h
	lda	crsrfmt
	rrc
	cc	crtini
	jmp	r5fc1


s131a:	mov	a,b
	sub	c
	jc	l133e
	cpi	013h
	jnc	l137f
	call	s1406
l1327:	mov	a,c	
	cmp	b	
	jz	l13e5
	call	s171d
	xchg
	mov	a,c
	inr	a
	call	s171d
	mov	c,a
	push	b
	call	copy80
	pop	b
	jmp	l1327

l133e:	adi	012h
	jc	l136a

	dcr	b
	jp	l1349

	mvi	b,018h
l1349:	call	s1406
	mov	a,c
	call	s171d
	mov	a,b
	sub	c
	jz	s1370
	jnc	l135a

	adi	019h
l135a:	push	h
	mvi	m,0f2h
	call	s13ec
	push	b
	call	s1370
	pop	b
	pop	h
	cmp	a
	jmp	l13a0

l136a:	call	s1406
	jmp	l13e0

s1370:	lda	r5f3e
	dcr	a
	jp	l1379

	mvi	a,018h
l1379:	call	s170b
	jmp	l1327

l137f:	inr	b
	call	s1406
	mov	a,b
	call	s171d
	mov	a,c
	sub	b
	jz	s13bf
	jnc	l1391

	adi	019h
l1391:	cmp	a
	push	h
	call	s13ec
	mvi	m,0f2h
	push	b
	call	s13bf
	pop	b
	pop	h
	ori	0ffh
l13a0:	mvi	c,050h
	lxi	d,rambase
	ldax	d
	inx	d
	mov	b,a
l13a8:	cnz	s13b2
	ldax	d
	inx	d
	mov	m,a
	dcr	b
	jnz	l13a8

s13b2:	mov	a,b
	mvi	b,000h
	dad	b
	mov	b,a
	mov	a,h
	sui	05ah
	rnz
	
	lxi	h,scrbeg
	ret


s13bf:	lda	r5f3e
	inr	a
	call	s1714
	call	s170b
	jmp	l13e0

l13cc:	mov	a,c	
	call	s171d
	xchg
	dcr	c
	jp	l13d7

	mvi	c,018h
l13d7:	mov	a,c
	call	s171d
	push	b
	call	copy80
	pop	b
l13e0:	mov	a,c
	cmp	b
	jnz	l13cc

l13e5:	mov	a,b
	call	s171d
	jmp	l003b


s13ec:	push	b
	lxi	d,cursor
	mvi	c,050h
	mov	b,a
	stax	d
	inx	d
l13f5:	cnz	s13b2
	mov	a,m
	mvi	m,0f2h
	stax	d
	inx	d
	dcr	b
	jnz	l13f5
	call	s13b2
	pop	b
	ret


s1406:	lda	r5f3e
	add	c
	mov	c,a
	sui	019h
	jc	l1411

	mov	c,a	
l1411:	lda	r5f3e
	add	b
	mov	b,a
	sui	019h
	rc
	mov	b,a
	ret


; copy 80 bytes from (HL) to (DE)
copy80:	mvi	c,20

; copy 4*C bytes from (HL) to (DE)
copy4c:	mov	a,m
	stax	d
	inx	h
	inx	d
	mov	a,m
	stax	d
	inx	h
	inx	d
	mov	a,m
	stax	d
	inx	h
	inx	d
	mov	a,m
	stax	d
	inx	h
	inx	d
	dcr	c
	jnz	copy4c
	ret


l1432:	add	a
	lxi	h,d172b-2
	jnc	l143c

	lhld	r5a7e
l143c:	mov	e,a
	mvi	d,000h
	dad	d
	mov	e,m
	inx	h
	mov	d,m
	push	d
	lhld	r5f38
	ret


l1448:	mov	a,c
	ani	07fh
	mov	c,a

l144c:	lhld	r5f36
	mov	m,c	
	inx	h
	shld	r5f36
	lxi	h,r5f38
	inr	m
	lda	r5f43
	cmp	m
	rnz

	lhld	r5f38
	dcr	l
	lda	r5af0
	rrc
	jnc	l1509
	jmp	xs1015


l146b:	call	xs1018
	mvi	b,05ch
	jmp	r5ff7


l1473:	out	strtbel
	ret	


l1476:	call	xs101b
	mov	a,b
	ori	080h
	mov	l,a
	mvi	h,05ah
	mov	m,c
	cpi	080h
	jnz	l1493

	mov	a,c
	rrc
	jnc	s126c
	
	lxi	h,r5b80
	lxi	d,r5c00
	jmp	s0023

l1493:	cpi	082h
	jz	s1245

	cpi	0f5h
	rnz
	
	mov	a,c
	ori	001h
	mov	m,a
	cpi	032h
	jc	l170e

	mvi	m,0feh
	call	xs100c
	jmp	l170e


l14ac:	lda	r5af8
	mov	c,a
	jmp	l144c


l14b3:	mvi	c,020h
	jmp	l144c


l14b8:	call	s1531
	lhld	r5f36
	lda	r5af7
	mov	m,a
	ret


l14c3:	call	xs1018
	jmp	l144c


l14c9:	call	xs1018
	mvi	a,080h
	ora	c	
	mov	c,a
	jmp	l144c


l14d3:	dcr	l
	jp	xs1015

	ret


l14d8:	call	s1561
	dcr	h
	jp	xs1015

	ret


l14e0:	inr	l
	lda	r5f43
	cmp	l
	jnz	xs1015

	ret


l14e9:	inr	h	
	call	s1561
	jmp	xs1015


l14f0:	dcr	l
	jp	xs1015

	mvi	l,04fh
l14f6:	call	s155c
	dcr	h
	jp	xs1015

	mov	c,a
	mvi	b,000h
	call	s131a
l1503:	lhld	r5f38
	jmp	xs1015


l1509:	inr	l	
	lda	r5f43
	sub	l
	jnz	xs1015

	lda	r5f42
	mov	l,a
l1515:	call	s155c
	inr	h
	call	s16e2

xs1015:	shld	r5f38
	mov	c,l
	lda	r5f3e
	add	h
	call	s171d
	shld	r5f3a
	mvi	b,000h
	dad	b
	shld	r5f36
	ret	


s1531:	dcr	l
	jp	xs1015

	lda	r5f43
	dcr	a
	mov	l,a
l153a:	call	s155c
	dcr	h
	jp	xs1015

	mov	h,a
	jmp	xs1015


l1545:	inr	l
	lda	r5f43
	sub	l
	jnz	xs1015

	lda	r5f42
	mov	l,a
l1551:	call	s155c
	jnz	l14e9

	mvi	h,000h
	jmp	xs1015


s155c:	push	h
	call	xs1015
	pop	h

s1561:	lda	r5af1
	dcr	a
	cmp	h
	rnc

	pop	psw
	ret


l1569:	call	xs101b
	lhld	r5f38
	shld	r5f3c
	lda	r5af2
	add	a
	jc	s157c

	mov	e,c
	mov	c,b
	mov	b,e

s157c:	rrc
	mov	d,a
	mov	a,c
	sub	d
	cpi	050h
	jnc	l1586

	mov	l,a
l1586:	call	s158c
	jmp	xs1015


s158c:	lda	r5af1
	mov	c,a
	dcr	a
	sub	h
	rc

	mov	a,b
	sub	d
	cmp	c
	rnc

	mov	h,a
	ret


l1599:	call	xs1018
	mov	a,c
	sui	020h
	rc

	mov	c,a
	mvi	a,019h
	lxi	h,r5af1
	mov	b,m
	sub	b
	cmp	c
	rc

	lhld	r5f47
	xchg
	lhld	r5f38
	mov	a,h
	sub	b
	jnc	l15bc

	sub	a
	add	c
	rz

	shld	r5f47
l15bc:	xchg
	sub	a
	add	c
	jz	xs1015
	
	mov	a,b
	dcr	a
	add	c
	mov	h,a
	mvi	l,000h
	jmp	xs1015


l15cb:	lhld	r5f3c
	jmp	xs1015


s15d1:	call	s0005
l15d4:	mvi	a,001h
	sta	r5f40
	sub	a
	mov	b,a
	mov	c,a
	lhld	r5f38
	jmp	s157c


l15e2:	lhld	r5f3a
l15e5:	xchg
	call	s171a
	xchg
	mov	a,l
	sub	e
	mov	a,h
	sbb	d
	jc	s1617

	push	d
	lxi	d,scrend
	call	s1617
	pop	d
	lxi	h,scrbeg
	jmp	s1617


l15ff:	lhld	r5f36
	jmp	l15e5
	

l1605:	lhld	r5f3a
	jmp	l003b


l160b:	lhld	r5f3a
	mvi	d,000h
	mvi	e,050h
	dad	d
	xchg
	lhld	r5f36
s1617:	lda	r5af7
	mov	c,a
	jmp	s0025


l161e:	call	xs101b
	mov	a,b
	call	s1638
	mov	b,a
	mov	a,c
	call	s1638
	mov	c,a
	call	s131a
	lhld	r5f38
l1631:	lda	r5f42
	mov	l,a
	jmp	xs1015


s1638:	ani	07fh
	cpi	020h
	jc	l1651
	sui	040h
	lxi	h,r5af1
	jc	l164c

	lxi	h,r5f39
	sui	020h
l164c:	add	m
	jp	l1651

	sub	a
l1651:	lxi	h,r5af1
	cmp	m
	rc

	mov	a,m
	dcr	a
	ret


l1659:	call	xs101b
	mov	a,c
	call	s168d
	mov	c,a
	mov	a,b
	call	s168d
	lhld	r5f3a
	mvi	b,000h
	dad	b
	mov	d,h
	mov	e,l
	sub	c
	jz	l1688
	jc	l167c
	
	inx	h
	mov	c,a
	call	s1803
	jmp	l1688

l167c:	dcx	h
	cma
	inr	a
	mov	c,a
l1680:	mov	a,m
	stax	d
	dcx	h
	dcx	d
	dcr	c
	jnz	l1680

l1688:	lda	r5af7
	stax	d
	ret


s168d:	cpi	050h
	rc

	sui	0a0h
	lxi	h,r5f38
	add	m
	jp	l169a

	sub	a
l169a:	cpi	050h
	rc

	mvi	a,04fh
	ret


xs1012:	lda	crsrfmt
	ana	a
	rm
	
	di
	mvi	a,080h
	out	crtcmd
	lda	r5f38
	out	crtparm
	lda	r5f39
	out	crtparm
	ei
	ret


xs100c:	di	
	mvi	a,080h
	out	crtcmd
	dcr	a
	out	crtparm
	out	crtparm
	ei
	ret


xs101b:	pop	h
	shld	r5f45
	call	xs1018
	mov	a,c
	sta	r5f3f
	call	xs1018
	lda	r5f3f
	mov	b,a
	lhld	r5f45
	pchl


xs1018:	pop	h
	shld	r5fbe

	mvi	a,0f7h		; rst 6 opcode
	sta	r5ff5
	ret


s16e2:	in	kbdstat
	rrc
	cc	s180f
	lda	r5af1
	dcr	a
	cmp	h
	rnc
	
	inr	h
	rz

	mov	h,a
	push	h
	lhld	r5f4b
	mov	a,h
	ora	l	
	jz	l16fc
	xthl
	ret

l16fc:	call	s1818
	lda	r5af1
	dcr	a
	mov	b,a
	mvi	c,000h
	call	s131a
	pop	h
	ret


s170b:	sta	r5f3e
l170e:	mvi	a,0efh
	sta	rst7
	ret


s1714:	cpi	019h
	rc
	sui	019h
	ret	


s171a:	lda	r5f3e
s171d:	call	s1714
	push	psw
	add	a
	mov	l,a
	mvi	h,05fh
	mov	a,m
	inx	h
	mov	h,m
	mov	l,a
	pop	psw
	ret


d172b:	dw	l146b,l1473,l1503,l1476
	dw	l14ac,l14b3,l14b8,l14c3
	dw	l1448,l14c9,l14d3,l14d8
	dw	l14e0,l14e9,l14f0,l14f6
	dw	l1509,l1515,s1531,l153a
	dw	l1545,l1551,l1569,l1599
	dw	l15cb,l1631,l15d4,s15d1
	dw	s0005,l15e2,l15ff,l1605
	dw	l160b,l161e,l1659

d1771:	db	014h,012h,011h,013h,01ch,000h,000h,01bh
	db	023h,01eh,020h,00ah,018h,00ch,00eh,00dh
	db	00bh,021h,01fh,01dh,010h,007h,022h,004h
	db	017h,019h

; init of sparse table
d178b:	db	014h,011h
	db	01ch,012h
	db	01dh,01bh
	db	01eh,014h
	db	01fh,013h
	db	07fh,003h	; rubout

d1797:	db	007h,002h	; bell
	db	008h,013h	; backspace
	db	00ah,012h	; line feed
	db	00dh,01ah	; carriage return
	db	01bh,001h	; escape
	db	000h,003h	; null
	db	020h,000h	; space


	db	"CORP INTEL corp.1981-83"

	fillto	017feh,0ffh

; checksum
	dw	04b33h
