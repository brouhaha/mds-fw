	cpu	8080

	include	ioc-io.inc
	include	ioc-flp.inc
	include ioc-mac.inc

	include ioc-ram.inc


; entry points in ROM 2

mget1d	equ    00814h


; entry points in ROM 2

s1009	equ    01009h
s100c	equ    0100ch
s1012	equ    01012h


	org	01800h

s1800:	jmp	xs1800
s1803:	jmp	xs1803	; copy C bytes from (HL) to (DE)
s1806:	jmp	xs1806	; unpack sparse table
keyc:	jmp	xkeyc	; cmd 012h - Requests data byte input from the keyboard.
kstc:	jmp	xkstc	; cmd 013h - Returns keyboard status byte to master.
s180f:	jmp	xs18d2
s1812:	jmp	xs1a0c
s1815:	jmp	xs196c
s1818:	jmp	xs1881
s181b:	jmp	xs1a4f


xkeyc:	lda	crsrow
	lxi	h,r5af6
	add	m
	sui	019h
	jnc	l182b

	sub	a
l182b:	inr	a
	sta	r5f40
	call	s197e
	jz	l1857
	mov	e,m
	inr	m
	mvi	d,05eh
	ldax	d
	lxi	h,r41ec
	mvi	m,001h
	cpi	07fh
	jnz	l1846

	mvi	m,004h
l1846:	cpi	020h
	cma			; (hw negative logic)
	out	dbbout
	rc

	lda	crscol
	lxi	h,05afbh
	cmp	m
	rnz

	out	strtbel
	ret	

l1857:	mvi	a,0ffh-07fh	; (hw negative logic)
	out	dbbout
	out	setcd
	ret


xkstc:	mvi	c,042h
s1860:	lxi	h,r41ec
	mov	a,m
	ana	a
	jz	l186c

	dcr	m
	jmp	l187c

l186c:	call	s197e
	jz	l187c

	in	kbdstat
	ani	008h
	jnz	l187b

	in	kbddat
l187b:	inr	c
l187c:	mov	a,c
	cma			; (hw negative logic)	
	out	dbbout
	ret


xs1881:	lxi	h,r5f40
	dcr	m
	rnz

	lda	r5af6
	mov	m,a
	lda	r5a81
	rrc
	rnc

	lxi	h,00000h
l1892:	in	kbdstat
	rrc
	jc	l18a0

	xthl
	xthl
	dcx	h
	mov	a,h
	ora	l
	jnz	01892h

l18a0:	in	kbddat
	cpi	013h		; carriage return
	rnz

l18a5:	in	kbdstat
	rrc
	jnc	l18a5
	jmp	l18a0


; Fill a sparse table in RAM from a dense table
; On entry:
;   DE points to dense table of two-byte entries
;   H is high byte of addr of sparse table in RAM
; Each dense table entry contains:
;   first byte - low byte of addr of sparse table entry
;   second byte - data to store in sparse table entry
; Last dense table entry has a second byte of zero
xs1806:	ldax	d
	inx	d
	mov	l,a
	ldax	d
	inx	d
	mov	m,a
	ana	a
	jnz	xs1806
	ret


; copy C bytes from (HL) to (DE)
xs1803:	mov	a,m
	stax	d
	inx	h
	inx	d
	dcr	c
	jnz	xs1803
	ret


;18c2
	push	h
	push	d
l18c4:	call	s197e
	jz	l18c4

	mov	e,m
	inr	m
	mvi	d,05eh
	ldax	d
	pop	d
	pop	h
	ret


xs18d2:	push	h
	push	d
	push	b
	in	kbddat
	mvi	h,05dh
	mov	l,a
	mov	a,m
	ana	a
	jp	l1931

	sui	0f0h
	jc	l18ed

	lhld	r5a7c
	call	s1aef
	jmp	l1934

l18ed:	mov	a,l
	ani	07fh
	mov	b,a
	ani	020h
	mov	c,a
	mov	a,m
	ani	03fh
	mov	d,a
	lhld	r5af2
	sub	a
	mov	l,a
	add	h
	cnz	s193b
	cnc	s1938
	jnc	l1934

l1907:	mov	a,m
	inx	h
	ana	a
	jp	l1929

	mov	d,a
	inr	a
	jz	l1934

	inr	a
	mov	e,b
	jz	l1928

	inr	a
	jnz	l1923
	mov	a,b
	ani	00fh
	adi	030h
	jmp	l1929

l1923:	mov	a,d
	ani	07fh
	xra	c
	mov	e,a
l1928:	mov	a,e
l1929:	push	h
	call	s1951
	pop	h
	jmp	l1907

l1931:	call	s1951
l1934:	pop	b
	pop	d
	pop	h
	ret


s1938:	lxi	h,d1b4d
s193b:	mov	a,d
	sub	m
	cmc
	rnc

	inx	h
	cmp	m
	rnc

	mov	e,a
	inx	h
	mvi	a,0ffh
l1946:	cmp	m
	inx	h
	jnz	l1946

	dcr	e
	jp	l1946
	stc
	ret


s1951:	lxi	h,r5f35
	mov	e,m
	mvi	d,05eh
	stax	d
	dcx	h
	mov	a,e
	inr	e
	sub	m
	mov	d,a
	lda	r5af9
	sub	d
	jnz	l196a

	lda	r5afa
	rrc
	rnc

	inr	m
l196a:	inx	h
	mov	m,e	

xs196c:	lxi	h,r41ee
	mov	a,m
	rrc
	rc

	mvi	l,0f0h
	mov	a,m
	ani	002h
	rz

	dcx	h
	mov	a,m
	ori	002h
	mov	m,a	
	ret


s197e:	in	kbdstat
	rrc
	cc	xs18d2
	lxi	h,r5f35
	mov	a,m
	dcx	h
	sub	m
	rz

	mvi	a,001h
	ret


l198e:	lda	r5ff5
	cpi	0f7h		; RST 6 opcode
	rz

	lda	r41fd
	rrc
	rc

	call	s1009
	lxi	h,m1c0f
	call	s19e5
	lxi	h,02241h
	push	h
	lxi	h,d1b62
	mov	a,m
	inx	h
l19ab:	cpi	0feh
	inx	h
	jz	l19d8

	dcx	h
	xthl
	push	psw
	mov	a,l
	stax	d
	inx	d
	mvi	a,':'
	stax	d
	inx	d
	mvi	a,' '
	stax	d
	inx	d
	mov	a,h
	stax	d
	inx	d
	pop	psw
	xthl

l19c4:	ani	07fh
	stax	d
	inx	d
	mov	a,m
	inx	h
	cpi	0ffh
	jnz	l19c4

	mvi	a,'"'
	stax	d
	inx	d
	mvi	a,00dh		; carriage return
	call	s19f4

l19d8:	xthl
	inr	l
	mov	a,l
	xthl
	cpi	'Z'+1
	mov	a,m
	inx	h
	jc	l19ab

	pop	h
	ret


s19e5:	lxi	d,scrbeg
	mov	b,d
	mov	c,e
l19ea:	mov	a,m
	inx	h
	ana	a
	rz

	call	s19f4
	jmp	l19ea


s19f4:	cpi	00dh		; carriage return
	jz	l19fc

	stax	d
	inx	d
	ret

l19fc:	xchg
	lxi	h,00050h
	dad	b
	mov	b,h
	mov	c,l
	xchg
	ret


l1a05:	lxi	h,r5f35
	mov	a,m
	dcx	h
	mov	m,a
	ret


xs1a0c:	lxi	h,d1c0b
	shld	r5a7c
	lxi	h,r5d00
l1a15:	mvi	a,07fh
	ana	l
	mov	m,a
	inr	l
	jnz	l1a15

	mvi	l,0b0h
	mvi	a,080h
	mvi	b,000h
	call	s1a3e

	mvi	l,0a0h
	mvi	a,082h
	call	s1a3e

	mvi	l,0c1h
	inr	b
	call	s1a48

	mvi	l,0e1h
	call	s1a48

	lxi	d,d1bef
	jmp	xs1806


s1a3e:	mvi	c,00ah
l1a40:	mov	m,a	
	add	b
	inr	l
	dcr	c
	jnz	l1a40
	ret	


s1a48:	mvi	a,083h
	mvi	c,01ah
	jmp	l1a40


xs1a4f:	lxi	h,00000h
l1a52:	in	dbbstat
	ani	dbbibf
	rz

	out	iocbusy
	dcx	h
	mov	a,h
	ora	l
	jnz	l1a52

	call	s100c
	lxi	h,mprst
	call	s19e5
	jmp	$


mprst:	db	"SERIES II I/O CONTROLLER",00dh,00dh
	db	"Press RESET",000h


xs1800:	ei	
	call	s1012
	in	miscin
	ani	diagmd
	rnz

	jmp	l1ac9


l1a9d:	call	s1012
l1aa0:	in	miscin
	ani	kbpres
	mvi	c,000h
	jz	01aabh
	mvi	c,002h

l1aab:	call	s1860
	in	dbbstat
	ani	dbbibf
	rnz

	out	iocbusy+1	; XXX why +1

	in	dbbstat
	ani	dbbcd
	in	dbbin
	cma			; (hw negative logic)
	out	clrcd
	jnz	l1b01

	cpi	013h		; carriage return
	jz	l1a9d
	jmp	l1ae1


l1ac9:	in	dbbstat
	ani	dbbibf
	rnz
	out	iocbusy+1	; XXX why +1
	in	dbbstat
	ani	dbbcd
	in	dbbin
	cma			; (hw negative logic)
	out	clrcd
	jnz	l1b01

	cpi	013h		; carriage return
	jz	l1aa0

l1ae1:	cpi	010h
	jz	l1afb

l1ae6:	mov	c,a
	sta	r41ed
	ani	01fh
	lhld	r41ea

s1aef:	add	a
	mov	e,a
	mvi	d,000h
	dad	d
	mov	e,m
	inx	h
	mov	d,m
	push	d
	jmp	s1012


l1afb:	lxi	b,crtstb
	call	mget1d

l1b01:	out	iocbusy
	mov	c,a
	call	r5ff5
	lxi	h,intena
	mov	a,m
	rrc
	jnc	l1b14

	dcx	h
	mov	a,m
	ani	001h
	mov	m,a	
l1b14:	in	dbbstat
	ani	dbbibf
	rnz

	call	s100c
l1b1c:	out	iocbusy+1	; XXX why +1
	in	dbbstat
	ani	dbbcd
	in	dbbin
	cma			; (hw negative logic)
	out	clrcd
	jnz	l1b3a

	cpi	013h		; carriage return
	jz	l1aa0

	cpi	010h
	jnz	l1ae6

	lxi	b,crtstb
	call	mget1d
l1b3a:	out	iocbusy
	mov	c,a
	call	r5ff5
	in	kbdstat
	ani	004h
	rz

	in	dbbstat
	ani	dbbibf
	jz	l1b1c
	ret	


d1b4d:	db	000h,01eh,0ffh,03ah,046h,0fdh,03ah,0ffh
	db	0feh,0feh,0feh,0feh,0feh,0ffh

; 1b5bh
	db	"/JOB"
	db	0fdh,00dh,0ffh


d1b62:	dbh	"AEDIT"
	db	020h,0ffh

	db	0feh,0ffh

	dbh	"COPY"
	db	020h,0ffh

	dbh	"DIR"
	db	020h,0ffh

	dbh	"CREDIT"
	db	020h,0ffh

	db	0feh,0ffh
	db	0feh,0ffh
	db	0feh,0ffh

	dbh	"ATTRIB"
	db	020h,0ffh

	dbh	"JOB"
	db	020h,0ffh

	dbh	"DELETE"
	db	020h,0ffh

	db	03ah
	dbh	"LP"
	db	03ah,020h,0ffh

	dbh	"LOGON"
	db	020h,0ffh

	dbh	"ASSIGN"
	db	020h,0ffh

	dbh	"LOGOFF"
	db	020h,0ffh

	db	03ah
	dbh	"SP"
	db	03ah,0ffh

	db	0feh,0ffh

	dbh	"RUN"
	db	020h,0ffh

	dbh	"SUBMIT"
	db	020h,0ffh

	db	" "
	dbh	"TO"
	db	" ",0ffh

	dbh	"ACCESS"
	db	" ",0ffh

	db	0feh,0ffh
	db	0feh,0ffh

	dbh	"EXPORT"
	db	020h,0ffh

	db	0feh,0ffh
	db	0feh,0ffh

	db	"/JOB0",00dh,0ffh	; why not high bit set on alpha chars?
	db	000h


d1bef:	db	094h,081h,09ch,081h,09dh,081h,09eh,081h
	db	09fh,081h,0a0h,081h,0aah,081h,0ffh,081h
	db	0c8h,0f0h,0e8h,0f0h,0c6h,0f1h,0e6h,0f1h
	db	0feh,09dh,000h,000h

d1c0b:	dw	l198e,l1a05

m1c0f:	db	"FUNC pressed with the following keys give sequences:",00dh,00dh
	db	"Number keys: \":Fn:\"     "
	db	"Shifted number keys: \"/JOBn\", carriage return",00dh,000h

	fillto	01ffeh,0ffh

; checksum
	dw	09633h
