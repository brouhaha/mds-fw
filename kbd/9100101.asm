; Intel Intellec Series II/III MDS unenhanced keyboard controller 8741A,
; Intel part number 9100101

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

; TEST0 (pin 1)  - tied directly to ground
; TEST1 (pin 39) - tied directly to ground
; XXX not sure why there are any jt[01], jnt[01] instructions,
;     possibly for a manufacturing test or to support
;     a different keyboard model


; RAM usage:
;   00h..07h:  register bank 0
;     00h         rb0 r0: pointer
;     01h         rb0 r1: pointer
;     07h         rb0 r7: keyboard row, 0-7
;   08h..0fh:  stack - only four levels available (two bytes each)
;                 hardware supports eight levels, 08h..17h
;   10h..17h:  FIFO data
;   18h..1fh:  register bank 1
;     18h         rb1 r0: pointer
;     19h         rb1 r1: pointer
;     1ah:        rb1 r2: temp
;     1bh:        rb1 r3: temp
;     1eh:        rb1 r6: ?
;   20h..2fh:
;   30h:       FIFO read pointer
;   31h:       FIFO write pointer
;   32h..3fh:


	cpu	8041

; Note that interrupts are not used. If they were, they would jump
; to locations 0003h (IBF) or 0007h (timer).

	org	0

reset:	cpl	f1		; set F1

	mov	r0,#3fh		; clear all RAM
	clr	a
X0004:	mov	@r0,a
	djnz	r0,X0004

	mov	@r0,a

	outl	p1,a		; disable keyboard row decoder

	mov	r0,#30h		; init FIFO pointers
	mov	@r0,#10h
	inc	r0
	mov	@r0,#10h

	mov	r7,#2
	cpl	f0		; set F0
	jmp	X005f


X0015:	jobf	X005b
	call	X017a
	jz	X001d
	mov	a,r2
	out	dbb,a
X001d:	jobf	X005b
	mov	r0,#20h
	mov	a,@r0
	jb4	X0026
	jmp	X005b

X0026:	mov	r0,#32h
	mov	a,@r0
	jz	X005f
	anl	a,#0feh
	jnz	X005b
	mov	r7,#2
	mov	r0,#34h
	inc	r0
	inc	r0
	mov	r3,#8
X0037:	mov	a,@r0
	jnz	X0040
	inc	r0
	inc	r7
	djnz	r3,X0037
	jmp	X005b

X0040:	clr	c
	mov	r5,#0
X0043:	rrc	a
	jc	X0049
	inc	r5
	jmp	X0043

X0049:	call	X0200
	jz	X004f
	call	X0150
X004f:	mov	r7,#0

	sel	rb1		; delay
	mov	r2,#0ffh
	mov	r3,#25h
X0056:	djnz	r2,X0056
	djnz	r3,X0056
	sel	rb0

X005b:	mov	r0,#32h
	clr	a
	mov	@r0,a
X005f:	mov	a,r7
	rr	a
	anl	a,#4
	mov	r2,a
	mov	a,r7
	rl	a
	anl	a,#8
	orl	a,r2
	mov	r2,a
	mov	a,r7
	swap	a
	rr	a
	anl	a,#10h
	orl	a,r2
	mov	r2,a
	mov	a,r7
	swap	a
	rl	a
	anl	a,#20h
	orl	a,r2
	orl	a,#3
	outl	p1,a
	anl	p1,#0fch
	in	a,p2
	cpl	a
	mov	r6,a
	mov	a,r7
	jb3	X0087
	mov	a,r6
	jz	X00ca
	jmp	X0097

X0087:	jb0	X0091
	mov	a,r6
	anl	a,#0efh
	mov	r6,a
	jz	X00ca
	jmp	X0097

X0091:	mov	a,r6
	anl	a,#0c7h
	mov	r6,a
	jz	X00ca
X0097:	mov	r4,#8
	mov	r5,#0
	clr	c
X009c:	rrc	a
	jc	X00a4
X009f:	inc	r5
	djnz	r4,X009c
	jmp	X00ca

X00a4:	sel	rb1
	mov	r6,a
	sel	rb0

	mov	r0,#32h
	mov	a,@r0
	inc	a
	mov	@r0,a
	mov	r0,#20h
	mov	a,@r0
	jb4	X00c5
	mov	a,r7
	add	a,#34h
	mov	r0,a
	mov	a,@r0
	mov	r3,a
	mov	a,r5
	xch	a,r3
	inc	r3
X00ba:	rrc	a
	djnz	r3,X00ba
	jc	X00c5
	call	X0200
	jz	X00c5
	call	X0150

X00c5:	sel	rb1
	mov	a,r6
	sel	rb0

	jmp	X009f


X00ca:	mov	a,r7
	add	a,#34h
	mov	r0,a
	mov	a,r6
	mov	@r0,a
	inc	r7
	mov	a,r7
	jb3	X00f0
	jmp	X005f

X00d6:	mov	r7,#2
	jmp	X0015


	fillto	00f0h,000h

X00f0:	jb0	X005f
	jb1	X00d6
	mov	r3,#0
	mov	a,#7
	outl	p1,a
	anl	p1,#0fch
	in	a,p2
	cpl	a
	anl	a,#10h
	mov	r5,a
	mov	a,#27h
	outl	p1,a
	anl	p1,#0fch
	in	a,p2
	cpl	a
	anl	a,#38h
	xrl	a,#20h
	mov	r2,a
	jb4	X011b
X010e:	jb3	X0122
X0110:	jb5	X0129
X0112:	mov	a,r5
	jb4	X012f
X0115:	mov	r1,#20h
	mov	a,r3
	mov	@r1,a
	jmp	X005f

X011b:	mov	a,#10h
	orl	a,r3
	mov	r3,a
	mov	a,r2
	jmp	X010e

X0122:	mov	a,#1
	orl	a,r3
	mov	r3,a
	mov	a,r2
X0127:	jmp	X0110

X0129:	mov	a,#2
	orl	a,r3
	mov	r3,a
	jmp	X0112

X012f:	mov	a,#8
	orl	a,r3
	mov	r3,a
	jmp	X0115

	fillto	0150h,000h

X0150:	jobf	X015d
	mov	r0,#31h
	mov	r1,#30h
	mov	a,@r1
	xrl	a,@r0
	jnz	X015d
	mov	a,r2
	out	dbb,a
	ret

X015d:	mov	a,r2
	sel	rb1
	mov	r0,#31h
	mov	r2,a
	mov	a,@r0
	mov	r3,a
	xrl	a,#17h
	jnz	X016a
	mov	r3,#0fh
X016a:	inc	r3
	mov	a,r3
	mov	r1,#30h
	xrl	a,@r1
	jz	X0178
	mov	a,r3
	mov	@r0,a
X0173:	mov	r0,a
	mov	a,r2
	mov	@r0,a
	sel	rb0
	ret

X0178:	sel	rb0		; could have used the previous two instruction
	ret			;   instead


X017a:	sel	rb1
	mov	r0,#31h
	mov	r1,#30h
	mov	a,@r1
	xrl	a,@r0
	jnz	X0185
	sel	rb0
	ret

X0185:	mov	a,@r1
	mov	r0,a
	xrl	a,#17h
	jnz	X018d
	mov	r0,#0fh
X018d:	inc	r0
	mov	a,r0
	mov	@r1,a
	mov	a,@r0
	sel	rb0
	mov	r2,a
	mov	a,#0ffh
	ret


	fillto	0200h,000h

X0200:	mov	a,r7
	add	a,#0feh
	anl	a,#7
	swap	a
	rr	a
	orl	a,r5
	mov	r3,a
	movp3	a,@a
	jz	X0247
	mov	r2,a
	xrl	a,#40h
	jnz	X021e
	mov	r0,#20h
	mov	a,@r0
	jb0	X021e
	anl	a,#8
	jz	X021e
	mov	a,#0
	jmp	X0243

X021e:	mov	a,r2
	jmp	X0252

X0221:	add	a,#9fh
	jc	X0229
	mov	a,#0
	jmp	X0233

X0229:	add	a,#0e6h
	jnc	X0231
	mov	a,#0
	jmp	X0233

X0231:	mov	a,#4
X0233:	mov	r0,#20h
	orl	a,@r0
	anl	a,#0fh
	add	a,#X02d0 & 0ffh
	movp	a,@a
	jb1	X0247
	jb0	X024a
	anl	a,#0c0h
	orl	a,r3
	movp3	a,@a
X0243:	mov	r2,a
	orl	a,#0ffh
	ret

X0247:	anl	a,#0
	ret

X024a:	anl	a,#0c0h
	orl	a,r3
	movp3	a,@a
	anl	a,#9fh
	jmp	X0243

X0252:	mov	r2,a
	mov	r0,#20h
	mov	a,@r0
	anl	a,#9
	xrl	a,#9
	jz	X025f
	mov	a,r2
	jmp	X0221

X025f:	mov	a,r2
	add	a,#91h
	jnz	X0269
	clr	f0
	cpl	f0
	mov	a,#0
	ret

X0269:	mov	a,r2
	add	a,#94h
	jz	X0271
	mov	a,r2
	jmp	X0221

X0271:	clr	f0
	mov	a,#0
	ret


	fillto	02d0h,000h

X02d0:	db	000h
	db	040h
	db	000h
	db	040h
	db	000h
	db	040h
	db	040h
	db	040h
	db	002h
	db	042h
	db	002h
	db	002h
	db	001h
	db	042h
	db	041h
	db	042h


	fillto	0300h,000h

; page 3 tables, accessed by movp3 instruction

; keyboard mapping tables
; 300-33f unshifted
; 340-37f shifted

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
	defkey	'z','Z'
	defkey	'x','X'
	defkey	'm','M'
	defkey	'v','V'
	defkey	000h,000h	; no key
	defkey	'c','C'
	defkey	'n','N'
	defkey	'b','B'

; row 4
	defkey	'0','~'
	defkey	'[','{'
	defkey	'o','O'
	defkey	'l','L'
	defkey	'9',')'
	defkey	'-','='
	defkey	'p','P'
	defkey	';','+'

; row 5
	defkey	's','S'
	defkey	'd','D'
	defkey	'k','K'
	defkey	'g','G'
	defkey	'a','A'
	defkey	'f','F'
	defkey	'j','J'
	defkey	'h','H'

; row 6
	defkey	'w','W'
	defkey	'e','E'
	defkey	'i','I'
	defkey	't','T'
	defkey	'q','Q'
	defkey	'r','R'
	defkey	'u','U'
	defkey	'y','Y'

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
	defkey	000h,000h	; repeat (special)
	defkey	000h,000h	; TPWR (special, alternate action)
				;    "Typewriter" mode, upper case lock
	defkey	000h,000h	; no key
	defkey	000h,000h	; no key

	org	$+040h

	fillto	0400h,000h

	end
