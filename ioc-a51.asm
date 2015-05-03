	cpu	8080

	include	ioc-io.inc
	include	ioc-flp.inc
	include ioc-mac.inc
	
; entry points in ROM 0

s000b	equ	0000bh
romt2c	equ	0002bh

; entry points in ROM 2

s1003	equ	01003h
s1006	equ	01006h
s1012	equ	01012h

; entry points in ROM 3

s1800	equ	01800h
s1809	equ	01809h
s180c	equ	0180ch
s180f	equ	0180fh
s1815	equ	01815h
s181b	equ	0181bh

; RAM, 4000h..5fffh

	org	041f7h
moshad	ds	1	; RAM shadow of miscout register
	ds	1
r41f9	ds	1

	org	05230h
scrbeg	ds	24*80	; start of screen buffer
scrend:			; ends at 05a00h (last byte used 059ffh)

	org	00800h

l0800:	jmp	xl0800
s0803:	jmp	xs0803
s0806:	jmp	xs0806
s0809:	jmp	xs0809
s080c:	jmp	xs080c
	jmp	xs080f		; XXX no external references?

	dw	d099e


s0814:	out	iocbusy
l0816:	in	dbbstat
	ani	002h
	jnz	l0816
	in	dbbstat
	ani	008h
	jz	l0828
	in	dbbin
	cma
	ret

l0828:	ldax	b
	ori	020h
	stax	b
	jmp	xl0800


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


s088e:	mvi	b,01ah	; XXX sector count?
	lxi	h,04232h
	lxi	d,04266h
	push	b
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

	pop	h
	pop	b
	mov	a,c	
	ana	a
	jnz	l08b4

l08ab:	mov	m,b	
	dcx	h
	dcx	h
	dcx	h
	dcx	h
	dcr	b
	jnz	l08ab

l08b4:	lxi	h,04200h
	mvi	b,01ah		; XXX sector count?
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


l08e3:	mov	a,c	
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


l091e:	lda	05af4h
	cpi	024h
	jnz	l09de

	call	s098d
	jmp	l0932


s092c:	out	iocbusy
	lxi	b,00d00h
	xchg

l0932:	mov	a,b	
	ora	c	
	rz

	dcx	b
	inr	b	
	inr	c
	lxi	d,0080ah
l093b:	call	s094a
	dcr	b	
	jnz	l093b

	ret


l0943:	in	dbbin
	cma
	mov	m,a	
	inx	h
	dcr	c	
	rz	

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


s098d:	call	s0814
	mov	l,a	
	call	s0814
	mov	h,a	
	call	s0814
	mov	c,a	
	call	s0814
	mov	b,a	
	ret


d099e:	dw	00000h
	dw	xl0800
	dw	l0a57
	dw	l0a81
	dw	l0ac7
	dw	l0b11
	dw	s09fa
	dw	l0b21
	dw	l0b41
	dw	l0b49
	dw	l0b54
	dw	l09de
	dw	l09de
	dw	l091e
	dw	l08e3
	dw	s1003
	dw	l0b60
	dw	l0b73
	dw	s1809
	dw	s180c
	dw	l09de
	dw	l0b93
	dw	s0a2d
	dw	l0ba1
	dw	l09de
	dw	l0bb2
	dw	l09de
	dw	l0bc5
	dw	l0bcc
	dw	l09de
	dw	l09de
	dw	l09de


l09de:	lda	041f1h
	ori	040h
	sta 	041f1h
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


; pulse miscout.unkout4 low very briefly
s09fa:	lda	moshad
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
	call	s09fa
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


s0a2d:	mvi	a,005h
	lxi	h,04102h
	cmp	m
	jc	l0a56

	lxi	b,041ffh
	call	s0814
	lhld	04102h
	mvi	h,000h
	lxi	b,041f8h
	dad	b
	mov	m,a	
	lxi	h,04102h
	inr	m
	mov	a,m
	cpi	005h
	jnz	l0a53

	call	xs0803
l0a53:	call	s0a1a
l0a56:	ret


l0a57:	lda	041f4h
	lxi	h,041f3h
	ana	m
	lxi	h,041ffh
	ana	m	
	ani	0f0h
	cpi	000h
	jz	l0a71

	lda	041f1h
	ori	080h
	sta	041f1h

l0a71:	lda	041f1h
	cma
	out	dbbout
	lxi	h,041f1h
	mvi	m,000h
	mvi	a,000h
	out	clrcd
	ret


l0a81:	lda	041f3h
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


l0ac7:	lxi	b,041f1h
	call	s0814
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

	lda	041f1h
	ori	010h
	sta	041f1h
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


l0b11:	lxi	h,041efh
	mvi	m,000h
	lxi	h,041f2h
	mvi	m,000h
	lxi	h,041eeh
	mvi	m,000h
	ret


l0b21:	lxi	b,041f1h
	call	s0814
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


l0b41:	mvi	c,000h
	call	romt2c	; same as romt2k, but with arg in C
	out	dbbout
	ret


l0b49:	lxi	d,04200h
	mvi	c,001h
	call	s000b
	out	dbbout
	ret

l0b54:	lxi	b,041f1h
	call	s0814
	ani	007h
	sta	041f0h
	ret

l0b60:	lxi	b,041f3h
	call	s0814
	mov	c,a	
	call	05ff5h
	lda	041efh
	ori	001h
	sta	041efh
	ret


l0b73:	lda	041edh
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


l0b93:	lxi	h,04102h
	mvi	m,000h
	mvi	c,0f7h
	call	s083f
	call	s0a2d
	ret


l0ba1:	lxi	b,041ffh
	call	s0814
	mov	c,a	
	lxi	d,04200h
	call	s092c
	call	s0a1a
	ret


l0bb2:	mvi	c,008h
	call	s0834
	lhld	041fah
	mov	c,l	
	lxi	d,04200h
	call	s095f
	call	s0a1a
	ret


l0bc5:	call	xs0809
	cma
	out	dbbout
	ret


l0bcc:	call	xs0806
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


xl0800:	lxi	h,04080h
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


s0d7b:	lda	041f8h
	ani	040h
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
	lda	r41f9
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
