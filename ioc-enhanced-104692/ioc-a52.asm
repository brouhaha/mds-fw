	cpu	8080

	include	ioc-io.inc
	include	ioc-flp.inc
	include ioc-mac.inc

	include ioc-ram.inc


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
	call	doclsh
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
	sta	nrolls
	lhld	r5f49
	call	xs1015
	pop	b	
	jmp	r5ff5


xs1006:	push	d
	lda	nrolls
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
	jmp	donop

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
	lda	nrolls
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
	lxi	d,r5c00+80h
	call	s0023
	call	s1812
	lxi	h,d1289
	lxi	d,r5af1
	mvi	c,00bh
	call	s1803
	call	s1245
	lxi	d,r5c00+'A'
	call	s1264
	lxi	d,r5c00+'a'
	call	s1264
	call	s126c
	call	doclsh
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
	lxi	d,r5b00+' '
	call	s0025
	pop	d
	jmp	s1806


s1264:	lxi	h,d1771
	mvi	c,01ah
	jmp	s1803


s126c:	lxi	h,r5b00
	lxi	d,r5b00+80h
	call	s127b
	lxi	h,r5c00
	lxi	d,r5c00+80h

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

s1370:	lda	nrolls
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


s13bf:	lda	nrolls
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


s1406:	lda	nrolls
	add	c
	mov	c,a
	sui	019h
	jc	l1411

	mov	c,a	
l1411:	lda	nrolls
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

	lhld	altcop		; alternate console output case table pointer
l143c:	mov	e,a
	mvi	d,000h
	dad	d
	mov	e,m
	inx	h
	mov	d,m
	push	d
	lhld	r5f38
	ret


domsb0:	mov	a,c
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
	jnc	docurr
	jmp	xs1015


; console output case: escape
doesc:	call	xs1018
	mvi	b,05ch
	jmp	r5ff7


; console output case: bell
dobell:	out	strtbel
	ret	


; console output case: set user flag (ESC X function)
doflag:	call	xs101b
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
	
	lxi	h,r5b00+80h
	lxi	d,r5b00+100h
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


domark:	lda	r5af8
	mov	c,a
	jmp	l144c


dospc:	mvi	c,' '
	jmp	l144c


dorubo:	call	doculw
	lhld	r5f36
	lda	r5af7
	mov	m,a
	ret


dolit:	call	xs1018
	jmp	l144c


domsb1:	call	xs1018
	mvi	a,080h
	ora	c	
	mov	c,a
	jmp	l144c


doculf:	dcr	l
	jp	xs1015

	ret


docuuf:	call	s1561
	dcr	h
	jp	xs1015

	ret


docurf:	inr	l
	lda	r5f43
	cmp	l
	jnz	xs1015

	ret


docudf:	inr	h	
	call	s1561
	jmp	xs1015


doculr:	dcr	l
	jp	xs1015

	mvi	l,04fh
docuur:	call	s155c
	dcr	h
	jp	xs1015

	mov	c,a
	mvi	b,000h
	call	s131a
donop:	lhld	r5f38
	jmp	xs1015


docurr:	inr	l	
	lda	r5f43
	sub	l
	jnz	xs1015

	lda	r5f42
	mov	l,a
docudr:	call	s155c
	inr	h
	call	s16e2

xs1015:	shld	r5f38
	mov	c,l
	lda	nrolls
	add	h
	call	s171d
	shld	r5f3a
	mvi	b,000h
	dad	b
	shld	r5f36
	ret	


doculw:	dcr	l
	jp	xs1015

	lda	r5f43
	dcr	a
	mov	l,a
docuuw:	call	s155c
	dcr	h
	jp	xs1015

	mov	h,a
	jmp	xs1015


docurw:	inr	l
	lda	r5f43
	sub	l
	jnz	xs1015

	lda	r5f42
	mov	l,a
docudw:	call	s155c
	jnz	docudf

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


dogoxy:	call	xs101b
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


dogopa:	call	xs1018
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


dorest:	lhld	r5f3c
	jmp	xs1015


doclsh:	call	s0005
dohome:	mvi	a,001h
	sta	r5f40
	sub	a
	mov	b,a
	mov	c,a
	lhld	r5f38
	jmp	s157c


docles:	lhld	r5f3a
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


doceos:	lhld	r5f36
	jmp	l15e5
	

doclrl:	lhld	r5f3a
	jmp	l003b


doceol:	lhld	r5f3a
	mvi	d,000h
	mvi	e,050h
	dad	d
	xchg
	lhld	r5f36
s1617:	lda	r5af7
	mov	c,a
	jmp	s0025


doidln:	call	xs101b
	mov	a,b
	call	s1638
	mov	b,a
	mov	a,c
	call	s1638
	mov	c,a
	call	s131a
	lhld	r5f38
doret:	lda	r5f42
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


doidch:	call	xs101b
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


s170b:	sta	nrolls
l170e:	mvi	a,0efh
	sta	rst7
	ret


s1714:	cpi	019h
	rc
	sui	019h
	ret	


s171a:	lda	nrolls
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


; dispatch for console output case numbers, starting with one
d172b:	dw	doesc	; ccesc:  escape
	dw	dobell	; ccbell: ring bell
	dw	donop	; ccnop:  do nothing
	dw	doflag	; ccflag: set user flag (ESC X function)
	dw	domark	; ccmark: display visible marker
	dw	dospc	; ccspc:  output a space
	dw	dorubo	; ccrubo: rubout
	dw	dolit 	; cclit:  display next char literally
	dw	domsb0	; ccmsb0: display next char with top bit masked off
	dw	domsb1	; ccmsb1: display next char with top bit turned on
	dw	doculf	; ccculf: cursor left freeze
	dw	docuuf	; cccuuf: cursor up freeze
	dw	docurf	; cccurf: cursor right freeze
	dw	docudf	; cccudf: cursor down freeze
	dw	doculr	; ccculr: cursor left roll
	dw	docuur	; cccuur: cursor up roll
	dw	docurr	; cccurr: cursor right roll
	dw	docudr	; cccudr: cursor down roll
	dw	doculw	; ccculw: cursor left wrap
	dw	docuuw	; cccuuw: cursor up wrap
	dw	docurw	; cccurw: cursor right wrap
	dw	docudw	; cccudw: cursor down wrap
	dw	dogoxy	; ccgoxy: cursor go to coordinates (ESC Y function)
	dw	dogopa	; ccgopa: cursor go to partition (ESC M function)
	dw	dorest	; ccrest: restore cursor to value before last ccgoxy
	dw	doret	; ccret:  carriage return, go to start of current line
	dw	dohome	; cchome: home the cursor within paritition
	dw	doclsh	; ccclsh: clear screen and home cursor
	dw	s0005	; cccls:  clear screen but don't home cursor
	dw	docles	; cccles: clear this line (all) to end of screen
	dw	doceos	; ccceos: clear to end of screen
	dw	doclrl	; ccclrl: clear entire line
	dw	doceol	; ccceol: clear to end of line
	dw	doidln	; ccidln: insert and delete line
	dw	doidch	; ccidch: insert and delete character

; default mapping for escape sequences
d1771:	db	cccuuw	; ESC A - cursor up wrap
	db	cccudr	; ESC B - cursor down roll
	db	cccurr	; ESC C - cursor right roll
	db	ccculw	; ESC D - cursor left wrap
	db	ccclsh	; ESC E - clear screen and home
	db	000h	; ESC F
	db	000h	; ESC G
	db	cchome	; ESC H - home cursor
	db	ccidch	; ESC I - insert and delete character
	db	cccles	; ESC J - clear from begining of this line to end of screen
	db	ccclrl	; ESC K - clear current line
	db	ccmsb1	; ESC L - display next char with top bit turned on (attribute)
	db	ccgopa	; ESC M - cursor go to partition
	db	cccuuf	; ESC N - cursor up freeze
	db	cccudf	; ESC O - cursor down freeze
	db	cccurf	; ESP P - cursor right freeze
	db	ccculf	; ESC Q - cursor left freeze
	db	ccceol	; ESC R - clear to end of line
	db	ccceos	; ESC S - clear to end of screen
	db	cccls	; ESC T - clear screen but don't home cursor
	db	cccuur	; ESC U - cursor up roll
	db	ccrubo	; ESC V - rubout: cursor left wrap, then blank char
	db	ccidln	; ESC W - insert and delete line
	db	ccflag	; ESC X - set user flag
	db	ccgoxy	; ESC Y - go to coordinates
	db	ccrest	; ESC Z - restore cursor to value before last goxy

; init of sparse table
d178b:	db	014h,cccurr	; right arrow - cursor right roll
	db	01ch,cccudr	; down arrow  - cursor down roll
	db	01dh,cchome	; home        - home cursor within partition
	db	01eh,cccuuw	; up arrow    - cursor up wrap
	db	01fh,ccculw	; left arrow  - cursor left wrap
	db	07fh,ccnop	; rubout      - ignore

d1797:	db	007h,ccbell	; bell
	db	008h,ccculw	; backspace - cursor left wrap
	db	00ah,cccudr	; line feed - cursor down roll
	db	00dh,ccret	; carriage return
	db	01bh,ccesc	; escape
	db	000h,ccnop	; null
	db	020h,ccdisp	; space


	db	"CORP INTEL corp.1981-83"

	fillto	017feh,0ffh

; checksum
	dw	04b33h
