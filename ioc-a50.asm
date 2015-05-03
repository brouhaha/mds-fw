	cpu	8080

	include	ioc-io.inc
	include	ioc-flp.inc
	include ioc-mac.inc

; entry points in ROM 1
l0800	equ	00800h
s0803	equ	00803h
s0806	equ	00806h
s0809	equ	00809h
s080c	equ	0080ch

; entry points in ROM 2
s1000	equ	01000h
s100c	equ	0100ch

; RAM, 4000h..5fffh

rambase	equ	04000h

	org	rambase
cursor	ds	2	; pointer into screen buffer for cursor loc
r4002	ds	1
r4003	ds	1
r4004	ds	1
r4005	ds	1
r4006	ds	1
r4007	ds	1
r4008	ds	1
r4009	ds	1
r400a	ds	1

	org	040d0h
r40d0	ds	2
r40d2	ds	2

	org	041f7h
moshad	ds	1	; RAM shadow of miscout register

r41f8	ds	1
r41f9	ds	1
	ds	1
r41fb	ds	2

	org	05230h
scrbeg	ds	24*80	; start of screen buffer
scrend:			; ends at 05a00h (last byte used 059ffh)

crsrfmt	equ	05af5h

r5af7	equ	05af7h

rst1	equ	05fa8h
rst2	equ	05fabh
rst3	equ	05faeh
rst4	equ	05fb1h
rst5	equ	05fb4h
rst6	equ	05fb7h

rst7	equ	05fc0h

	org	00000h

	di
	sub	a
	jmp	reset

s0005:	jmp	l0202

; XXX insert macro to check address = 0008h
	jmp	rst1

s000b:	mvi	b,016h
	jmp	l018b
	
; XXX insert macro to check address = 0010h
	jmp	rst2

	fillto	00018h,0ffh

; XXX insert macro to check address = 0018h
	jmp	rst3
	
; 001b - XXX unreferenced?
	mvi	c,000h
	jmp	l01ec
	
; XXX insert macro to check address = 0020h
	jmp	rst4

s0023:	mvi	c,000h
	jmp	l01c6

; XXX insert macro to check address = 0028h
	jmp	rst5

; ROM test
romt2c:	mov	a,c	; start at C * 2K
romt2k:	add	a	; start at A * 2K
	jmp	xsromt

; XXX insert macro to check address = 0030h
	jmp	rst6

crtini:	push	b
	push	d
	jmp	xcrtin
	

; XXX insert macro to check address = 0038h
	jmp	rst7


l003b:	lda	r5af7
	mov	c,a
	mvi	a,00ah
	jmp	l01ec

	
reset:	sub	a
	out	crtcmd
	out	dmamclr		; DMAC master clear (8237 only)
	mvi	a,020h
	sta	crsrfmt
	mvi	a,dmaena+mastint
	sta	moshad

	lxi	sp,l005b
	call	crtini
	dw	l005b		; return address (call can't store into ROM)

l005b:	mvi	a,tmsrfsh+trboth+trategn  ; refresh timer to rate gen mode and load
	out	timermd		; 31 cycles of 2 MHz, 19.84 us interval
	mvi	a,01fh
	out	trefrsh
	sub	a
	out	trefrsh

	mvi	a,tmshorz+trboth+tonesht  ; horizontal timer to one-shot mode and load
	out	timermd

	in	miscin
	ani	hz50
	add	a
	add	a
	adi	02ch
	out	thoriz
	sub	a
	out	thoriz

	mvi	a,tmsbell+trboth+tonesht  ; bell timer to one-shot and load
	out	timermd			  ; value = 5632 (8.7 ms)
	sub	a
	out	tbell
	mvi	a,016h
	out	tbell

	out	010h		; XXX does nothing?

	in	dmactmp		; DMAC temp reg (8237 only, 8257 reads 0ffh)
	sui	001h		; set borrow if read as 000h (8237)
	sbb	a		; A=000h if 8257, A=0ffh if 8237
	ani	004h		; A=000h if 8257, A=004h if 8237
	out	dmamode		; write 000h to disable all channels if 8257
				; write 004h to disable controller if 8237

	sub	a		; A=000h
	out	dmaclbp		; NOP (8257), DMA clear byte pointer (8237)
	out	dmac0a
	out	dmac0a
	out	dmac0tc
	out	dmac0tc

	mvi	a,050h		; single mode, addr incr, autoinit enable,
				;   verify transfer, chan 0 select
	out	dmawmod		; NOP (8257), DMA write mode register (8237)

	mvi	a,00eh		; set channel 1, 2, 3 mask bits (disable DRQ)
	out	dmawamr		; NOP (8257) DMA write all mask register (8237)

	in	dmactmp		; DMAC temp reg (8237 only, 8257 reads 0ffh)
	adi	0ffh		; set carry if non-zero (8257)
	sbb	a		; A=000h (8237), A=0ffh (8257)
	ori	dextwrt		; (8257), ??? (8237)
	ani	dautold+dextwrt+dmaen0	; (8257), ??? (8237)
	out	dmamode		; mode set (8257), command (8237)
	
	in	miscin
	ani	diagmd
	jz	l0138
	sub	a

	lxi	sp,l00bb
	call	romt2k
	dw	l00bb		; return address (call can't store into ROM)

l00bb:	jz	l00bb

	mvi	a,001h
	lxi	sp,l00c8
	call	romt2k
	dw	l00c8		; return address (call can't store into ROM)

l00c8:	jz	l00c8

	mvi	a,dmaena+mastint
	out	miscout

	lxi	sp,l00d7
	call	ringbl
	dw	l00d7		; return address (call can't store into ROM)

; test bell timer
l00d7:	mvi	a,dmaena+mastint+bellen
	out	miscout
	mvi	a,001h
	out	tbell
	out	tbell

	lxi	h,012ch
l00e4:	dcx	h
	mov	a,h
	ora	l
	jnz	l00e4
	in	miscin
	ani	belltmr
l00ee:	jnz	l00ee

	sub	a
	out	tbell
	mvi	a,016h
	out	tbell

	lxi	sp,00100h
	call	ringbl
	dw	l0100		; return address (call can't store into ROM)

l0100:	mvi	a,dmaena+mastint
	out	miscout
	
	lxi	sp,l010c
	call	ringbl
	dw	l010c		; return address (call can't store into ROM)
	
l010c:	in	miscin		; XXX used where?

	mvi	c,020h
	lxi	d,rambase
	mvi	b,016h

	lxi	sp,l011d
	call	ramtst
	dw	l011d		; return address (call can't store into ROM)

l011d:	jz	l011d
	lxi	d,rambase
	mvi	b,0e9h

	lxi	sp,l012d
	call	ramtst
	dw	l012d

l012d:	jz	l012d

	lxi	sp,l0138
	call	ringbl
	dw	l0138

l0138:	lxi	sp,04040h
	call	s1000
	call	crtini
	rst	7
	in	miscin
	ani	diagmd
	jz	l0800
	jmp	l0683


; ring the bell (assuming that it is enabled by miscout.bellen)
ringbl:	out	strtbel
l014e:	in	miscin
	ani	belltmr
	jz	l014e
l0155:	in	miscin
	ani	belltmr
	jnz	l0155
	ret


; write BC to the bell timer
s015d:	mov	a,c
	out	tbell
	mov	a,b
	out	tbell
	ret


; verify checksum of a 2KB ROM, 2KB aligned
; on entry, A is the address over 1024
; note that the code that jumps here has already multiplied A by 2a
xsromt:	add	a	; HL += A * 1024
	add	a
	mov	h,a
	sub	a
	mov	l,a

	mvi	b,008h
l016b:	add	m
	inr	l
	jnz	l016b
	inr	h
	dcr	b
	jnz	l016b
	sui	055h
	sui	001h
	sbb	a
	ret


; test all 8K of ROM
romt8k:	lxi	d,00004h
l017e:	mov	a,d
	call	romt2k
	mov	a,d
	rz
	inr	d
	dcr	e
	jnz	l017e
	mov	a,d
	ret	


l018b:	push	d	
	call	ramtst
	pop	d	
	rz	


	mvi	b,0e9h
ramtst:	mov	h,d
	mov	l,c
l0195:	mov	a,d
	xra	e
	xra	b
	stax	d
	inr	e
	jnz	l0195
	inr	d
	dcr	l
	jnz	l0195
	stax	d
	mov	l,d

; if in diagnostic mode, delay to make sure mem refresh is working
	in	miscin
	ani	diagmd
	jz	l01b4
	
	lxi	d,0ffffh	; time delay
l01ae:	dcx	d
	mov	a,d
	ora	e
	jnz	l01ae

l01b4:	mov	d,l
	mov	l,e
l01b6:	mov	a,h
	xra	l
	xra	b
	cmp	m
	inx	h
	jz	l01b6
	mov	a,e
	sub	l
	mov	a,d
	sbb	h
	sbb	a
	ret

l01c4:	mov	m,c	
	inx	h	

l01c6:	mov	a,e
	sub	l	
	ani	007h
	jnz	l01c4
	
	mov	a,e	
	sub	l	
	mov	e,a	
	mov	a,d	
	sbb	h	
	mov	d,a	
l01d3:	mov	a,d	
	sui	008h
	jc	l01e1

	mov	d,a	
	sub	a	
	call	l01ec
	jmp	l01d3

l01e1:	mov	a,d	
	rrc	
	rrc	
	rrc	
	mov	d,a	
	mov	a,e	
	rrc	
	rrc	
	rrc	
	add	d
	rz


l01ec:	mov	b,c
l01ed:	mov	m,c
	inx	h
	mov	m,b
	inx	h
	mov	m,c
	inx	h
	mov	m,b
	inx	h
	mov	m,c
	inx	h
	mov	m,b
	inx	h
	mov	m,c
	inx	h
	mov	m,b
	inx	h
	dcr	a
	jnz	l01ed
	ret


l0202:	lda	r5af7
	mov	c,a
	mov	b,a
s0207:	lxi	h,scrbeg
	mvi	a,0fah
	jmp	l01ed


s020f:	xchg
	mvi	m,020h
	inx	h
	mov	a,c	
	ani	07fh
	mov	m,a	
	cpi	07fh
	jz	l0226

	cpi	020h
	rnc

	adi	040h
	mov	m,a	
	dcx	h
	mvi	m,05eh
	ret

l0226:	mvi	m,04fh
	dcx	h
	mvi	m,052h
	ret	


s022c:	mov	a,c
	xchg
	mvi	c,008h
	mvi	m,030h
	ral
	jnc	l0238
	mvi	m,031h
l0238:	inx	h
	dcr	c
	jnz	00230h
	ret


s023e:	mov	a,b
	xra	c
	mov	b,a
	lxi	h,04200h
	lxi	d,00180h
	jmp	l01b6


s024a:	lhld	cursor
l024d:	ldax	b
	ora	a
	jz	l0258
	mov	m,a
	inx	b
	inx	h
	jmp	l024d

l0258:	call	s0278
	ret


s025c:	lxi	h,04200h
	mov	a,b
	xra	c
	mov	b,a	
	mvi	c,002h
	jmp	ramtst


s0267:	in	miscin
	ani	kbpres
	jz	s0267

	in	kbdstat
	ani	001h
	jz	s0267

	in	kbddat
	ret


; advance one line (without scrolling, no check for end of page)
s0278:	lhld	cursor
	lxi	d,80
	dad	d
	shld	cursor
	ret


s0283:	lxi	h,00000h
l0286:	in	miscin
	ani	belltmr
	jz	l0296
	inx	h	
	mov	a,h	
	ora	l	
	jnz	l0286
	jmp	$

l0296:	shld	r40d0
	mov	d,h	
	mov	e,l	
l029b:	in	crtstat
	ani	crtsir
	jnz	l02ab

	inx	h	
	mov	a,h	
	ora	l
	jnz	l029b
	jmp	$

l02ab:	shld	r40d2
	mov	a,e	
	sub	l	
	mov	a,d
	sbb	h	
	jnc	$
	
	dcr	d	
	jnz	$

	mvi	c,09dh
	in	dmactmp		; DMAC temp reg (8237 only, 8257 reads 0ffh)
	ana	a	
	jz	l02c3

	mvi	c,08fh
l02c3:	mov	a,c	
	sub	e	
	jc	$
	ret


s02c9:	lxi	h,scrbeg
	mvi	b,019h
	mvi	d,040h
l02d0:	mvi	c,050h
	mov	a,d	
	inr	d	
l02d4:	mov	m,a	
	inx	h
	inr	a	
	cpi	07fh
	jc	l02de
	
	mvi	a,040h
l02de:	dcr	c	
	jnz	l02d4
	dcr	b	
	jnz	l02d0

	ret	

; Note that code that jumps here has already pushed BC and DE
xcrtin:	di	
	push	h

; set up for CRTC commands
; H is screen comp byte 2
; E is screen comp byte 3
; L with the 030h bits from crsrfmt merged in is
;     screen comp byte 3

; assume 60 Hz
; H = 0d5h  bits 7..6 = 3:  4 row counts per VRTC
;           bits 5..0 = 21: 21 vertical rows per frame
; E = 089h  bits 7..4 = 8:  line number of underline = 9
;           bits 3..0 = 9:  10 scan lines per character row
; L = 0c9h  bit 8 = 1:      line counter offset by 1 count
;           bit 7 = 1:      field attribute mode non-transparent
;           bits 6..5:      cursor format, filled in from crsrfmt
;           bits 4..0 = 9:  20 character counts per HRTC
	lxi	h,058c9h
	mvi	e,089h

	lda	moshad
	out	miscout
	mov	c,a	

	in	miscin		; check 50 hz flag
	mov	b,a
	rrc
	jnc	l02ff

; set up for 50 Hz
; H = 098h  bits 7..6 = 2:  3 row counts per VRTC
;           bits 5..0 = 24: 24 vertical rows per frame
; E = 08ah: bits 7..4 = 8:  line number of underline = 9
;           bits 3..0 = 10: 11 scan lines per character row
; L = 0cch  bit 8 = 1:      line counter offset by 1 count
;           bit 7 = 1:      field attribute mode non-transparent
;           bits 6..5:      cursor format, filled in from crsrfmt
;           bits 4..0 = 12: 26 character counts per HRTC
	inr	e
	lxi	h,098cch

l02ff:	mvi	a,unused4
	xra	c	
	out	miscout

	in	miscin		; check for undocumented misc input
	xra	b		; why XOR with previous miscin?

	ani	unkin10		; unknown bit, perhaps detects IOC-III?
	jz	l0314

	mov	a,e		; move underline up one line
	sui	010h
	mov	e,a

	mov	a,l		; don't offset line counter by 1 count
	sui	080h
	mov	l,a

l0314:	sub	a		; CRTC reset command
	out	crtcmd
	
	mvi	a,04fh		; screen comp byte 1
				;   bit 7 = 0: normal rows
				;   bits 6..0 = 04fh: 80 char/row
	out	crtparm

	mov	a,h		; screen comp byte 2
	out	crtparm
	
	mov	a,e		; screen comp byte 3
	out	crtparm

	lda	crsrfmt		; merge the curor format into screen comp byte 4
	ani	030h
	sta	crsrfmt
	ora	l
	out	crtparm

	mvi	a,crteni
	out	crtcmd

	mvi	a,crtstrt+00ah	; two dma cycles per burst,
				; 15 char clocks between DMA requests
	out	crtcmd

	pop	h
	pop	d
	pop	b
	ret


s0338:	call	s0267
	cpi	014h
	jz	00000h		; reset
	ani	0dfh		; fold LC to UC
	cpi	'D'
	jz	dgdisk		; disk
	cpi	'G'
	jz	dggen		; general
	cpi	'K'
	jz	dgkbd		; keyboard
	jmp	s04b5


mdiagb:	db	"SERIES II IOC DIAGNOSTIC V1.5",000h

d0372:	db	00ah,018h,000h,001h,04ch,018h,006h,00ah
	db	007h,001h,007h,018h,008h,001h,008h,004h
	db	008h,00ah,008h,007h

d0386:	db	000h,055h,02ah		; control-@, U, *
	db	0aah,0ffh

mtstp:	db	"TEST PASSED",000h

m0397:	db	"D - Disk  G - General  K - Keyboard/CRT",000h

m03bf:	db	"ERROR",000h

mdiskt:	db	"DISK TEST",000h

mnodsk:	db	"NO INTEGRAL DISK",000h

minscr:	db	"Insert SCRATCH disk and type \"#\".",000h

d0402:	db	000h,002h,01ah,000h,000h
d0402ln	equ	$-d0402

m0407:	db	"READ ERROR",000h

m0412:	db	"ROM   CHECKSUM FAILED",000h

mfunc:	db	"FUNC  ",000h

mkprmt:	db	"TYPE CNTL-@, U, *",000h

mkdlog:	db	"       REQUESTED     RECEIVED",000h

mkhasf:	db	"Is there a FUNC-key ? Y or N",000h

mkfprm:	db	"Type FUNC-*, Func-RUBOUT",000h

merr2:	db	"ERROR"
merr2ln	equ	$-merr2


s049a:	call	s0005
	lxi	h,scrbeg
	shld	cursor
	ret


s04a4:	lxi	b,mtstp
	call	s024a
	ret


s04ab:	call	s0278
	lxi	b,m0397
	call	s024a
	ret


s04b5:	call	s049a
	lxi	b,mdiagb	; diagnostic sign-on message
	call	s024a
	ret	


; disk diagnostic
dgdisk:	call	s049a
	lxi	b,mdiskt
	call	s024a
	in	miscin
	ani	flppres
	cpi	000h
	jnz	l04d8
	lxi	b,mnodsk
	call	s024a
	ret


l04d8:	call	s080c
	lxi	h,041ffh
	mvi	m,000h
	lxi	h,041fdh
	mvi	m,000h
	inx	h	
	mvi	m,000h
	lxi	b,minscr
	call	s024a
	call	s0267
	cpi	'#'
	jz	l04f7
	ret


l04f7:	call	s0806
	call	s0806
	mvi	l,d0402ln
	lxi	d,r41f8
	lxi	b,d0402
l0505:	ldax	b
	stax	d
	inx	b
	inx	d
	dcr	l
	jnz	l0505

	lxi	h,r4002
	mvi	m,000h
l0512:	mvi	a,maxtrk-1
	lxi	h,r4002
	cmp	m
	jc	l0536

	lda	r4002
	sta	r41fb
	call	s0803
	call	s05db
	rar
	jnc	l052c
	ret

l052c:	lda	r4002
	inr	a	
	sta	r4002
	jnz	l0512

l0536:	lxi	h,r41f9
	mvi	m,006h
	inx	h	
	mvi	m,003h
	lxi	h,r4002
	mvi	m,000h

l0543:	mvi	a,009h
	lxi	h,r4002
	cmp	m
	jc	l0582

	lhld	r4002
	mvi	h,000h
	lxi	b,d0372
	dad	h
	dad	b
	mov	e,m
	inx	h	
	mov	d,m
	xchg
	shld	r41fb

	lhld	r4002
	mvi	h,000h
	lxi	b,d0372
	dad	h
	dad	b
	mov	c,m
	inx	h	
	mov	b,m
	call	s025c
	call	s0803
	call	s05db
	rar	
	jnc	l0578
	ret	

l0578:	lda	r4002
	inr	a
	sta	r4002
	jnz	l0543

l0582:	lxi	h,r41f9
	mvi	m,004h
	lxi	h,r4002
	mvi	m,000h

l058c:	mvi	a,009h
	lxi	h,r4002
	cmp	m
	jc	l05d7

	lhld	r4002
	mvi	h,000h
	lxi	b,d0372
	dad	h
	dad	b
	mov	e,m
	inx	h
	mov	d,m
	xchg
	shld	r41fb
	call	s0803
	call	s05db
	rar
	jnc	l05b1
	ret
	
l05b1:	lhld	r4002
	mvi	h,000h
	lxi	b,d0372
	dad	h
	dad	b
	mov	c,m
	inx	h
	mov	b,m
	call	s023e
	cma
	rar
	jnc	l05cd

	lxi	b,00407h
	call	s024a
	ret

l05cd:	lda	r4002
	inr	a
	sta	r4002
	jnz	l058c

l05d7:	call	s04a4
	ret


s05db:	call	s0809
	sta	r4003
	cpi	000h
	jnz	l05e9
	mvi	a,000h
	ret

l05e9:	lxi	b,m03bf
	call	s024a
	lxi	d,6
	lhld	cursor
	dad	d
	xchg
	mvi	a,050h
	call	s07d7
	xchg
	lhld	r4003
	mov	c,l	
	call	s022c
	mvi	a,0ffh
	ret


dggen:	call	s049a
	call	romt8k
	sta	r4004
	cpi	004h
	jnc	l0624
	
	lxi	b,00412h
	call	s024a
	lda	r4004
	adi	030h
	sta	scrbeg+4
	ret	

l0624:	call	s04a4
	ret	


dgkbd:	call	s02c9
l062b:	call	s0267
	sta	r4005
	sui	01bh
	adi	0ffh
	sbb	a
	push	psw
	lda	r4005
	sui	020h
	adi	0ffh
	sbb	a
	pop	b
	mov	c,b
	ana	c
	rar
	jnc	l067f
	
	lxi	h,scrbeg
	shld	cursor
	lhld	r4005
	mov	c,l	
	lxi	d,r4006
	call	s020f
	lda	r4006
	cpi	020h
	jnz	l0664

	lda	r4007
	sta	r4006

l0664:	lhld	r4006
	mov	b,h
	mov	c,l
	call	s0207
	lda	r4005
	ani	080h
	cpi	000h
	jz	l067c

	lxi	b,mfunc
	call	s024a
l067c:	jmp	l062b

l067f:	call	s04b5
	ret


l0683:	call	s100c
	di
	mvi	a,dmaena+mastint+bellen
	out	miscout
	lxi	b,003b6h
	call	s015d
	in	crtstat
	sta	r4008

; wait until CRTC interrupt request
l0696:	in	crtstat
	ani	crtsir		; interrupt request
	cpi	000h
	jnz	l06a2
	jmp	l0696		; no, loop

l06a2:	mvi	a,000h
	out	strtbel
	call	rst7
	di
	call	s0283
	lxi	b,01600h
	call	s015d
	call	ringbl
	mvi	a,dmaena+mastint
	out	miscout
	call	ringbl
	mvi	a,dmaena+mastint+bellen
	out	miscout
	call	ringbl
	mvi	a,dmaena+mastint
	out	miscout
	call	ringbl
	ei	
	call	s04b5
	call	s0278
	lxi	b,mkprmt
	call	s024a
	call	s0278
	lxi	b,mkdlog
	call	s024a
	call	s0278

	lxi	h,r4009	; clear response counter
	mvi	m,000h

l06e9:	mvi	a,004h
	lxi	h,r4009
	cmp	m	
	jc	l07ca
	lda	r4009
	cpi	003h
	jnz	l0724

	lxi	b,mkhasf
	call	s024a
l0700:	call	s0267
	ani	0dfh		; fold LC to UC
	sta	r400a
	lda	r400a
	cpi	'N'
	jnz	l0713		; why isn't this just a jz l07ca?
	jmp	l07ca

l0713:	lda	r400a
	cpi	'Y'
	jz	l071e		; why isn't this just a jnz l0700
	jmp	l0700

l071e:	lxi	b,mkfprm
	call	s024a
l0724:	call	s0267
	sta	r400a
	lhld	r4009
	mvi	h,000h
	lxi	b,d0386
	dad	b
	lxi	d,00006h
	push	h
	lhld	cursor
	dad	d
	xthl
	mov	c,m
	pop	d	
	call	s020f
	lhld	r4009
	mvi	h,000h
	lxi	b,d0386
	dad	b
	lxi	d,00009h
	push	h	
	lhld	cursor
	dad	d
	xthl
	mov	c,m
	pop	d
	call	s022c
	lxi	d,00014h
	lhld	cursor
	dad	d
	xchg
	lhld	r400a
	mov	c,l	
	call	s020f
	lxi	d,00017h
	lhld	cursor
	dad	d	
	xchg
	lhld	r400a
	mov	c,l	
	call	s022c
	lhld	r4009
	mvi	h,000h
	lxi	b,d0386
	dad	b
	lda	r400a
	cmp	m
	jz	l07b6

	mvi	l,merr2ln
	lxi	d,00022h
	push	h	
	lhld	cursor
	dad	d
	xchg
	lxi	b,merr2
	pop	h	

l0795:	ldax	b
	stax	d
	inx	b
	inx	d
	dcr	l	
	jnz	l0795

	lhld	r4009
	mvi	h,000h
	lxi	b,d0386
	dad	b
	lda	r400a
	xra	m	
	lxi	d,00029h
	lhld	cursor
	dad	d
	xchg
	mov	c,a	
	call	s022c

l07b6:	lxi	d,00050h
	lhld	cursor
	dad	d	
	shld	cursor
	lda	r4009
	inr	a	
	sta	r4009
	jnz	l06e9

l07ca:	call	s04ab
	call	s0338
	jmp	l07ca

	jmp	$		; unreachable
	ret


s07d7:	mov	c,a
	mvi	b,000h
	mov	a,e
	sub	c
	mov	l,a
	mov	a,d
	sbb	b
	mov	h,a
	ret


	db	"CORP INTEL corp.1981-83"

	fillto	007feh,0ffh

; checksum
	dw  00f33h
