; Intel Intellec Series II/III MDS keyboard controller (KBD) 8741A

; (partially) reverse engineered by Eric Smith <spacewar@gmail.com>

; assembles with asl (Macro Assembler AS)
;   http://john.ccac.rwth-aachen.de:8000/as/


fillto	macro	dest,value
	while	$<dest
	db	value
	endm
	endm


; PORT definitions

; P17..P16 unused
; P15..P12 select for keyboard row decoder
;             P15 least significant, P12 most significant
; P11..P10 enables for keyboard row decoder, active low

; P27..P20 keyboard column inputs

	cpu	8041

reset:	mov	r0,#3fh		; clear all RAM
	clr	a
X0003:	mov	@r0,a
	djnz	r0,X0003

	outl	p1,a		; disable keyboard row decoder
	mov	r0,#11h
	mov	@r0,#20h
	inc	r0
	mov	@r0,#20h
	clr	f1
	cpl	f1
	clr	f0
	cpl	f0
	jnt1	X0016
	jmp	X0200

X0016:	mov	r7,#0
X0018:	call	X0026
	mov	a,r7
	add	a,#0fah
	jc	X0031
	mov	a,r6
	jz	X0039
	call	X005f
	jmp	X0018


X0026:	mov	a,#X00d0 & 0ffh
	add	a,r7
	movp	a,@a
	outl	p1,a		; select keyboard row
	anl	p1,#0fch	; enable keyboard row decoder
	in	a,p2		; read keyboard columns
	cpl	a
	mov	r6,a
	ret


X0031:	call	X003d
	jnz	X0018
	call	X0110
	jmp	X0016


X0039:	call	X0092
	jmp	X0018


X003d:	mov	r0,#10h
	jnz	X004c
	mov	r4,#0fbh
	mov	r3,#0efh
	mov	a,r6
	anl	a,#10h
	rr	a
	rr	a
	jmp	X0055

X004c:	mov	r4,#0c7h
	mov	r3,#0c7h
	mov	a,r6
	anl	a,#38h
	xrl	a,#20h

X0055:	mov	r1,a
	mov	a,@r0
	anl	a,r4
	orl	a,r1
	mov	@r0,a
	mov	a,r6
	anl	a,r3
	mov	r6,a
	jz	X0092

X005f:	mov	a,r7
	add	a,#34h
	mov	r0,a
	mov	a,@r0
	orl	a,r6
	xrl	a,@r0
	jz	X0092
	mov	r5,#0
	clr	c
X006b:	rrc	a
	jc	X0071
X006e:	inc	r5
	jmp	X006b

X0071:	sel	rb1
	mov	r7,a
	sel	rb0
	call	X016b
	jz	X008c

	call	X00a8
	mov	r0,#13h
	mov	a,r7
	mov	@r0,a
	inc	r0
	mov	a,r5
	mov	@r0,a
	inc	r0
	jt1	X00a1

	mov	@r0,#0
	inc	r0
	mov	@r0,#1
X0089:	sel	rb1
	mov	r6,#0
X008c:	sel	rb1
	mov	a,r7
	sel	rb0
	clr	c
	jnz	X006e

X0092:	mov	a,r7
	add	a,#34h
	mov	r0,a
	mov	a,r6
	mov	@r0,a
	inc	r7
	mov	a,r7
	xrl	a,#8
	jnz	X00a0
	mov	r7,#0
X00a0:	ret

X00a1:	mov	@r0,#3fh
	inc	r0
	mov	@r0,#1
	jmp	X0089


X00a8:	jobf	X00b5
	mov	r0,#12h
	mov	r1,#11h
	mov	a,@r1
	xrl	a,@r0
	jnz	X00b5
	mov	a,r2
	out	dbb,a
	ret

X00b5:	mov	a,r2
	sel	rb1
	mov	r2,a
	mov	r0,#12h
	mov	a,@r0
	mov	r3,a
	xrl	a,#2fh
	jnz	X00c2

	mov	r3,#1fh
X00c2:	inc	r3
	mov	a,r3
	mov	r1,#11h
	xrl	a,@r1
	jz	X00ce

	mov	a,r3
	mov	@r0,a
	mov	r0,a
	mov	a,r2
	mov	@r0,a
X00ce:	sel	rb0
	ret


X00d0:	db	13h
	db	33h
	db	0bh
	db	2bh
	db	1bh
	db	3bh
	db	07h
	db	27h


X00d8:	mov	r0,#12h
	mov	r1,#11h
	mov	a,@r1
	xrl	a,@r0
	jnz	X00e1
	ret

X00e1:	mov	a,@r1
	mov	r0,a
	xrl	a,#2fh
	jnz	X00e9
	mov	r0,#1fh

X00e9:	inc	r0
	mov	a,r0
	mov	@r1,a
	mov	a,@r0
	mov	r2,a
	mov	a,#0ffh
	ret


	fillto	0100h,0ffh

	db	00h
	db	02h
	db	40h
	db	42h
	db	00h
	db	01h
	db	40h
	db	42h
	db	00h
	db	02h
	db	40h
	db	02h
	db	40h
	db	41h
	db	40h
	db	42h
	

X0110:	jobf	X0110
	call	X00d8
	jz	X0118
	mov	a,r2
	out	dbb,a

X0118:	mov	r0,#10h
	mov	a,@r0
	jb4	X0159

	mov	r0,#13h
	mov	a,@r0
	mov	r7,a
	jt1	X015b

	call	X0026
X0125:	mov	r3,a
	clr	c
	cpl	c
	mov	r0,#14h
	mov	a,@r0
	mov	r4,a
	inc	r4
	clr	a
X012e:	rlc	a
	djnz	r4,X012e
	anl	a,r3
	jz	X0159
	sel	rb1
	mov	r0,#15h
	mov	a,@r0
	dec	a
	mov	@r0,a
	jnz	X0159
	mov	a,r6
	mov	@r0,a
	inc	r0
	mov	a,@r0
	dec	a
	mov	@r0,a
	jnz	X0159
	jt1	X0162
	mov	a,#1
	mov	@r0,a
	dec	r0
	mov	a,#23h
	mov	@r0,a
X014d:	mov	r6,a
	sel	rb0
	mov	r0,#14h
	mov	a,@r0
	mov	r5,a
	call	X016b
	jz	X0159
	call	X00a8
X0159:	sel	rb0
	ret
X015b:	call	X0264
	call	X0220
	mov	a,r6
	jmp	X0125

X0162:	mov	a,#1
	mov	@r0,a
	dec	r0
	mov	a,#8
	mov	@r0,a
	jmp	X014d


X016b:	mov	a,r7
	swap	a
	rr	a
	orl	a,r5
	mov	r3,a
	movp3	a,@a
	jz	X01a8
	mov	r2,a
	mov	r0,#10h
	mov	a,@r0
	jb4	X01b0
	anl	a,#0ch
	jz	X0188
	xrl	a,#0ch
	jz	X01cd
	jb2	X0188
	mov	a,r2
	xrl	a,#40h
	jz	X01a4
X0188:	mov	a,r2
	anl	a,#80h
	swap	a
	rl	a
	mov	r4,a
	mov	a,@r0
	anl	a,#0efh
	orl	a,r4
	rr	a
	rr	a
	add	a,#0
	movp	a,@a
	jb1	X01a8
	mov	r4,a
	anl	a,#0c0h
	orl	a,r3
	movp3	a,@a
	anl	a,#7fh
	xch	a,r4
	jb0	X01aa
	mov	a,r4
X01a4:	mov	r2,a
	mov	a,#0ffh
	ret

X01a8:	clr	a
	ret

X01aa:	mov	a,r4
	anl	a,#9fh
	mov	r2,a
	jmp	X01a4

X01b0:	call	X0188
	mov	a,r2
	orl	a,#80h
	mov	r2,a
	mov	r0,#10h
	mov	a,@r0
	anl	a,#4
	jz	X01c1
	mov	a,r2
	anl	a,#0bfh
	mov	r2,a
X01c1:	call	X00a8
	jmp	X01a8

X01c5:	jf0	X01c8
	cpl	f0
X01c8:	jmp	X01a8
X01ca:	clr	f0
	jmp	X01a8
X01cd:	mov	a,r2
	jb7	X01d2
	jmp	X01a8

X01d2:	anl	a,#7fh
	mov	r2,a
	add	a,#91h
	jz	X01c5
	add	a,#3
	jz	X01ca
	jmp	X01a8


	db	"(C) INTEL CORP 1982"

	fillto	0200h,0ffh

X0200:	mov	r7,#0
X0202:	mov	r5,#0
	clr	a
	mov	r6,a
	mov	r3,a
	mov	a,r7
	add	a,#0fah
	jnc	X021c
	mov	r0,#10h
	jnz	X0218
	mov	a,@r0
	anl	a,#4
	rl	a
	rl	a
	mov	r3,a
	jmp	X021c
X0218:	mov	a,@r0
	anl	a,#38h
	mov	r3,a
X021c:	call	X0220
	jmp	X024c


X0220:	mov	a,r7
	add	a,#34h
	mov	r0,a
	mov	a,@r0
	orl	a,r3
	outl	p2,a		; drive keyboard columns???

X0227:	mov	a,#X03f6 & 0ffh
	add	a,r5
	movp3	a,@a
	mov	r3,a

	mov	a,#X03ee & 0ffh
	add	a,r7
	movp3	a,@a
	orl	a,r3

	outl	p1,a		; keyboard row decoder
	orl	p1,#1		; disable keyboard row decoder
	mov	a,r6
	jt0	X0241
	anl	p1,#0feh	; enable keyboard row decoder
	nop
	orl	p1,#1		; disable keyboard row decoder
	nop
	jt0	X0241
	orl	a,#1
X0241:	rr	a
	mov	r6,a
	anl	p1,#0feh	; enable keyboard row decoder
	inc	r5
	mov	a,r5
	xrl	a,#8
	jnz	X0227
	ret


X024c:	mov	a,r7
	add	a,#0fah
	jc	X025c
	mov	a,r6
	jz	X0258
	call	X005f
	jmp	X0202
X0258:	call	X0092
	jmp	X0202
X025c:	call	X003d
	jnz	X0202
	call	X0110
	jmp	X0200
X0264:	mov	r5,#0
	clr	a
	mov	r6,a
	mov	r3,a
	mov	a,r7
	add	a,#0fah
	jnc	X0278
	mov	r0,#10h
	jnz	X0279
	mov	a,@r0
	anl	a,#4
	rl	a
	rl	a
	mov	r3,a
X0278:	ret
X0279:	mov	a,@r0
	anl	a,#38h
	mov	r3,a
	ret

	fillto	0300h,0ffh

; page 3 tables, accessed by movp3 instruction

; keyboard mapping tables
; 300-33f unshifted
; 240-37f shifted

defkey	macro	uns,shf
	db	uns
	org	$+03fh
	db	shf
	org	$-040h
	endm

; row 2
	defkey	009h,009h	; tab
	defkey	'@','`'
	defkey	',','<'
	defkey	00dh,00dh	; carriage return
	defkey	' ',' '
	defkey	':','*'
	defkey	'.','>'
	defkey	'/','?'

; row 3
	defkey	'z'+080h,'Z'
	defkey	'x'+080h,'X'
	defkey	'm'+080h,'M'
	defkey	'v'+080h,'V'
	defkey	000h,000h	; no key
	defkey	'c'+080h,'C'
	defkey	'n'+080h,'N'
	defkey	'b'+080h,'B'

; row 4
	defkey	'0','~'
	defkey	'[','{'
	defkey	'o'+080h,'O'
	defkey	'l'+080h,'L'
	defkey	'9',')'
	defkey	'-','='
	defkey	'p'+080h,'P'
	defkey	';','+'

; row 5
	defkey	's'+080h,'S'
	defkey	'd'+080h,'D'
	defkey	'k'+080h,'K'
	defkey	'g'+080h,'G'
	defkey	'a'+080h,'A'
	defkey	'f'+080h,'F'
	defkey	'j'+080h,'J'
	defkey	'h'+080h,'H'

; row 6
	defkey	'w'+080h,'W'
	defkey	'e'+080h,'E'
	defkey	'i'+080h,'I'
	defkey	't'+080h,'T'
	defkey	'q'+080h,'Q'
	defkey	'r'+080h,'R'
	defkey	'u'+080h,'U'
	defkey	'y'+080h,'Y'

; row 7
	defkey	'2','"'
	defkey	'3','#'
	defkey	'8','('
	defkey	'5','%'
	defkey	'1','!'
	defkey	'4','$'
	defkey	'7','\''
	defkey	'6','&'

; row 8
	defkey	07fh,07fh	; rubout
	defkey	01dh,01dh	; home
	defkey	'\\','|'
	defkey	014h,014h	; right arrow
	defkey	000h,000h	; control (special)
	defkey	01fh,01fh	; left arrow
	defkey	']','}'
	defkey	01eh,01eh	; up arrow

; row 9
	defkey	01bh,01bh	; escape
	defkey	01ch,01ch	; down arrow
	defkey	'_','^'
	defkey	000h,000h	; shift (special)
	defkey	000h,000h	; function (special), was repeat on unenhanced
	defkey	000h,000h	; TPWR (special, alternate action)
				;    "Typewriter" mdoe, upper case lock
	defkey	000h,000h	; no key
	defkey	000h,000h	; no key

	org	$+080h

	fillto	03eeh,0ffh

X03ee:	db	10h
	db	18h
	db	20h
	db	28h
	db	30h
	db	38h
	db	08h
	db	00h

X03f6:	db	00h
	db	02h
	db	04h
	db	06h
	db	80h
	db	82h
	db	84h
	db	86h

	fillto	0400h,0ffh

	end
