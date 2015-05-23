; Intel Intellec Series II/III MDS IOC parallel I/O controller (PIO) 8041A

	cpu	8041

fillto	macro	dest,value
	while	$<dest
	db	value
	endm
	endm

	org	0
	jmp	reset

	fillto	0003h,000h
	jmp	ibfirq

	add	a,#23h

	fillto	0007h,000h
	jmp	tmrirq

X0009:	orl	p1,#0ffh
	anl	p2,#0fch
	anl	p2,#0efh
	in	a,p1
	en	i
	orl	p2,#10h
	orl	p2,#3
	anl	a,#15h
	mov	r2,a
	swap	a
	inc	a
	anl	a,#0eh
	orl	a,r2
	anl	a,#0fh
	mov	r2,a
	dis	i
	mov	r1,#26h
	mov	a,@r1
	anl	a,r2
	jz	X002d
	mov	r1,#21h
	orl	a,@r1
	mov	@r1,a
	orl	p2,#80h
X002d:	jmp	X0009

ibfirq:	clr	f0
	cpl	f0
	sel	rb1
	mov	r2,a
	orl	p2,#7fh
	in	a,dbb
	mov	r7,a
	jf1	X003b
	jmp	X03de

X003b:	clr	f1
	xch	a,r5
	jz	X0041
	jmp	X0100

X0041:	xch	a,r5
	mov	r0,#27h
	mov	@r0,a
	anl	a,#0e0h
	xch	a,r7
	anl	a,#1fh
	mov	r6,a
	add	a,#0f0h
	jnc	X0051
	jmp	cmd1x

X0051:	jmp	cmd0x

X0053:	anl	p2,#0efh
X0055:	orl	p2,#10h
	orl	p2,#7fh
X0059:	clr	f0
	mov	a,r2
	retr

X005c:	mov	r5,#0
	clr	f0
	mov	a,r2
	retr

tmrirq:	mov	r4,a
	orl	p2,#7fh
	call	X03d2
	mov	r3,a
	inc	r7
	inc	r6
	inc	r5
	mov	a,r3
	jb4	X0077
	jb6	X0077
	mov	a,r7
	xrl	a,#0afh
	jnz	X007d
	mov	r7,a
	jmp	X0079

X0077:	mov	a,#2
X0079:	mov	r0,#24h
	call	X00b0
X007d:	mov	a,r3
	jb0	X0088
	mov	a,r6
	xrl	a,#0dh
	jnz	X008e
	mov	r6,a
	jmp	X008a

X0088:	mov	a,#2
X008a:	mov	r0,#23h
	call	X00b0
X008e:	mov	a,r3
	jb2	X0099
	mov	a,r5
	xrl	a,#0dh
	jnz	X009f
	mov	r5,a
	jmp	X009b

X0099:	mov	a,#2
X009b:	mov	r0,#22h
	call	X00b0
X009f:	call	X03c9
	clr	a
	jt1	X00a6
	mov	a,#2
X00a6:	mov	r0,#25h
	call	X00b0
	orl	p2,#10h
	orl	p2,#7fh
	mov	a,r4
	retr

X00b0:	xch	a,@r0
	anl	a,#0fdh
	orl	a,@r0
	mov	@r0,a
	ret

X00b6:	mov	r3,#96h
X00b8:	jt1	X00bc
	jmp	X00d5

X00bc:	jmp	X00be

X00be:	jmp	X00c0

X00c0:	djnz	r3,X00b8
	orl	p2,#10h
	orl	p2,#7fh
	mov	r1,#25h
	mov	a,#80h
	orl	a,@r1
	mov	@r1,a
	mov	a,#0ffh
	clr	f1
	cpl	f1
	out	dbb,a
	clr	a
	mov	@r1,a
	clr	c
	ret

X00d5:	clr	c
	cpl	c
	ret

X00d8:	call	X03d2
	anl	a,r4
	jz	X00e0
	clr	c
	cpl	c
	ret

X00e0:	jtf	X00e4
	jmp	X00e0

X00e4:	djnz	r3,X00d8
	mov	a,#80h
	orl	a,@r1
	mov	@r1,a
	clr	c
	ret

X00ec:	mov	r4,a
	mov	r0,#28h
	anl	a,@r0
	jnz	X00f8
	mov	r0,#27h
	mov	a,@r0
	jb7	X00f8
	ret

X00f8:	mov	r0,#26h
	mov	a,r4
	orl	a,@r0
	mov	@r0,a
	ret

X00fe:	movp	a,@a
	ret

X0100:	add	a,#3
	jmpp	@a

	jmp	X010e

	inc	r0
	inc	r4
	inc	r4
	inc	r4
	inc	r4
	inc	r4
	xch	a,@r0
	xch	a,@r0
	xch	a,@r0
X010e:	mov	r0,#23h
X0110:	mov	a,#20h
	orl	a,@r0
	mov	@r0,a
	mov	r5,#0
	jmp	X0041

	mov	r0,#24h
	jmp	X0110

	mov	r0,#25h
	jmp	X0110

	mov	r0,#20h
	jmp	X0110

	jmp	X005c

; handle commands 000h through 00fh
cmd0x:	mov	a,r6
	add	a,#ctbl0x & 0ffh
	jmpp	@a

ctbl0x:	db	reset & 0ffh	; pacify - reset PIO and its devices
	db	ereset & 0ffh	; ereset - reset device-generated error
	db	systat & 0ffh	; systat - get subsystem status byte
	db	dstat & 0ffh	; dstat - get device status byte
	db	srqdak & 0ffh	; srqdak - device interrupt acknowledge
	db	srqack & 0ffh	; srqack
	db	srq & 0ffh	; srq
	db	decho & 0ffh	; decho
	db	xcsmem & 0ffh	; csmem
	db	xtram & 0ffh	; tram
	db	xsint & 0ffh	; sint

; remainder undefined
	db	badc0x & 0ffh
	db	badc0x & 0ffh
	db	badc0x & 0ffh
	db	badc0x & 0ffh
	db	badc0x & 0ffh

xcsmem:	jmp	csmem

xtram:	jmp	tram

xsint:	jmp	sint

badc0x:	jmp	badc1x

reset:	dis	i
	stop	tcnt
	dis	tcnti
	orl	p1,#0ffh
	mov	a,#7fh
	outl	p2,a
	anl	p2,#0f5h
	anl	p2,#0efh
	mov	a,#0ffh
	mov	t,a
	strt	t
X0152:	jtf	X0156
	jmp	X0152

X0156:	orl	p2,#10h
	orl	p2,#0ah
	sel	rb0
	mov	r0,#3fh
	clr	a
X015e:	mov	@r0,a
	djnz	r0,X015e
	mov	a,#0
	mov	psw,a
	clr	f0
	clr	f1
	call	X016b
	en	tcnti
	jmp	X0009

X016b:	retr


ereset:	jmp	badc1x


systat:	mov	r0,#22h		; merge MSB of device status bytes from r22 through r25
	mov	a,@r0
	mov	r0,#23h
	orl	a,@r0
	mov	r0,#24h
	orl	a,@r0
	mov	r0,#25h
	orl	a,@r0
	anl	a,#0f0h
	mov	r1,a
	jz	X0181		; any devices have error?
	mov	r1,#80h		; yes, set device error in system status byte
X0181:	clr	a
	mov	r0,#20h
	xch	a,@r0
	orl	a,r1
	out	dbb,a
	jmp	X005c

dstat:	mov	r0,#22h		
	mov	a,@r0
	mov	r1,#0f0h
	anl	a,r1
	mov	r3,a
	jz	X0194
	mov	r3,#40h
X0194:	mov	r0,#23h
	mov	a,@r0
	anl	a,r1
	jz	X019e
	mov	a,#10h
	orl	a,r3
	mov	r3,a
X019e:	mov	r0,#24h
	mov	a,@r0
	anl	a,r1
	jz	X01a8
	mov	a,#20h
	orl	a,r3
	mov	r3,a
X01a8:	mov	r0,#25h
	mov	a,@r0
	anl	a,r1
	jz	X01b2
	mov	a,#80h
	orl	a,r3
	mov	r3,a
X01b2:	clr	a
	mov	r0,#21h
	xch	a,@r0
	orl	a,r3
	out	dbb,a
	jmp	X005c

; cmd 004h - device interrupt acknowledge
srqdak:	mov	r5,#8
	jmp	X0059

X01be:	mov	a,r7
	cpl	a
	anl	a,#0fh
	mov	r7,a
	mov	r0,#26h
	anl	a,@r0
	mov	@r0,a
	mov	a,r7
	swap	a
	orl	a,r7
	mov	r0,#21h
	anl	a,@r0
	mov	@r0,a
	mov	a,r7
	jnz	X01d9
	mov	r0,#20h
	mov	a,#10h
	orl	a,@r0
	mov	@r0,a
	jmp	X005c

X01d9:	anl	p2,#7fh
	jmp	X005c

srqack:	clr	a
	mov	r0,#26h
	mov	@r0,a
	mov	r0,#21h
	mov	a,#0f0h
	anl	a,@r0
	mov	@r0,a
	anl	p2,#7fh
	jmp	X005c

srq:	orl	p2,#80h
	jmp	X005c

decho:	mov	r5,#9
	jmp	X0059

X01f3:	mov	a,r7
	cpl	a
	out	dbb,a
	jmp	X005c

X01f8:	movp	a,@a
	ret

	fillto	0200h,000h

; cmd 008h
csmem:	clr	c
	clr	a
	mov	r3,a
	mov	r4,a
X0204:	mov	a,r3
	call	X00fe
	addc	a,r4
	mov	r4,a
	djnz	r3,X0204
X020b:	mov	a,r3
	call	X01f8
	addc	a,r4
	mov	r4,a
	djnz	r3,X020b
X0212:	mov	a,r3
	movp	a,@a
	addc	a,r4
	mov	r4,a
	djnz	r3,X0212
X0218:	mov	a,r3
	call	X03fd
	addc	a,r4
	mov	r4,a
	djnz	r3,X0218
	mov	a,r4
	add	a,#34h
	jnz	X0227
	out	dbb,a
	jmp	X005c

X0227:	mov	a,#0ffh
	cpl	f1
	out	dbb,a
	jmp	X0059


; cmd 009h
tram:	sel	rb0
	mov	r0,#3fh
	mov	a,#55h
X0232:	mov	@r0,a
	djnz	r0,X0232
	mov	r0,#3fh
X0237:	mov	a,#55h
	xrl	a,@r0
	jnz	X0252
	djnz	r0,X0237
	mov	r0,#3fh
	mov	a,#0aah
X0242:	mov	@r0,a
	djnz	r0,X0242
	mov	r0,#3fh
X0247:	mov	a,#0aah
	xrl	a,@r0
	jnz	X0252
	djnz	r0,X0247

	clr	a
	out	dbb,a
	jmp	reset


X0252:	mov	a,#0ffh
	cpl	f1
	out	dbb,a
	jmp	reset


; cmd 00ah
sint:	mov	r5,#0ah
	jmp	X0059


X025c:	mov	r0,#28h
	mov	a,r7
	anl	a,#0fh
	mov	@r0,a
	jmp	X005c

badc1x:	mov	r0,#20h
	mov	a,#40h
	orl	a,@r0
	mov	@r0,a
	jmp	X0059

; handle commands 010h through 01fh
; note that 010h has already been subtraced from command value in A
cmd1x:	add	a,#ctbl1x & 0ffh
	jmpp	@a

ctbl1x:
; paper tape reader
	db	rdrc & 0ffh	; rdrc
	db	rstc & 0ffh	; rstc

; paper tape punch
	db	punc & 0ffh	; punc
	db	pstc & 0ffh	; pstc

; printer
	db	xlptc & 0ffh	; lptc
	db	xlstc & 0ffh	; lstc

; PROM programmer
	db	xwppc & 0ffh	; wppc
	db	xrppc & 0ffh	; rppc
	db	xrpstc & 0ffh	; rpstc
	db	xrdpdc & 0ffh	; rdpdc

; remainder undefined
	db	badc1x & 0ffh
	db	badc1x & 0ffh
	db	badc1x & 0ffh
	db	badc1x & 0ffh
	db	badc1x & 0ffh
	db	badc1x & 0ffh


xlptc:	jmp	lptc

xlstc:	jmp	lstc

xwppc:	jmp	wppc

xrppc:	jmp	rppc

xrpstc:	jmp	rpstc

xrdpdc:	jmp	rdpdc


; cmd 010h
rdrc:	mov	r5,#0
	mov	r1,#22h
	mov	r4,#4
	mov	r3,#0eh
	call	X00d8
	jnc	X02b5
	sel	rb0
	mov	r5,#0
	sel	rb1
	mov	a,#4
	call	X00ec
	mov	a,r7
	jb6	X02ab
	anl	p2,#0dfh
	anl	p2,#0efh
	in	a,p1
	clr	f1
	out	dbb,a
	jmp	X0055

X02ab:	jb5	X02b1
	anl	p2,#0f7h
	jmp	X0053

X02b1:	anl	p2,#0f8h
	jmp	X0053

X02b5:	mov	a,r7
	jb6	X02be
	clr	a
	xch	a,@r1
	cpl	f1
	out	dbb,a
	jmp	X0059

X02be:	mov	a,#80h
	orl	a,@r1
	mov	@r1,a
	jmp	X005c


; cmd 011h
rstc:	mov	r0,#22h
	call	X03d2
	anl	a,#4
	jmp	X0337


; cmd 012h
punc:	mov	r5,#1
	jmp	X0059


X02d0:	mov	r5,#0
	mov	r1,#23h
	mov	r4,#1
	mov	r3,#0eh
	call	X00d8
	jnc	X02ea
	sel	rb0
	mov	r6,#0
	sel	rb1
	mov	a,#1
	call	X00ec
	mov	a,r7
	outl	p1,a
	anl	p2,#0f6h
	jmp	X0053

X02ea:	jmp	X005c


; cmd 003h
pstc:	mov	r0,#23h
	call	X03d2
	anl	a,#1
	jmp	X0339


	fillto	0300h,000h

X0300:	jmp	X005c

X0302:	jmp	X02be


; cmd 014h
lptc:	mov	r5,#2
	jmp	X0059


; command 002h
X0308:	mov	r5,#0
	mov	r1,#24h
	mov	r4,#10h
	mov	r3,#0afh
	call	X00d8
	jnc	X0300
	sel	rb0
	mov	r7,#0
	sel	rb1
	mov	a,#2
	call	X00ec
	mov	a,r7
	cpl	a
	outl	p1,a
	anl	p2,#0f9h
	jmp	X0053


; command 015h
lstc:	mov	r0,#24h
	call	X03d2
	anl	a,#50h
	xrl	a,#40h
	mov	r1,a
	mov	a,@r0
	anl	a,#2
	rr	a
	rr	a
	rr	a
	orl	a,#10h
	anl	a,r1
	rr	a
	rr	a
X0337:	rr	a
	rr	a
X0339:	mov	r1,a
	mov	a,@r0
	anl	a,#2
	xch	a,@r0
	orl	a,r1
	mov	r1,a
	mov	a,r7
	anl	a,#80h
	rr	a
	orl	a,r1
	out	dbb,a
	jmp	X005c


; command 016h
wppc:	mov	r5,#3
	jmp	X0059


; command 003h
X034c:	mov	r5,#4
	mov	a,r7
	outl	p1,a
	anl	p2,#0f1h
	jmp	X0053

; command 004h
X0354:	mov	r5,#5
	mov	a,r7
	outl	p1,a
	anl	p2,#0f2h
	jmp	X0053

; command 005h
X035c:	mov	r5,#0
	mov	r1,#25h
	call	X03c9
	jt1	X0302
	orl	p2,#10h
	orl	p2,#7fh
	mov	a,#8
	call	X00ec
	mov	a,r7
	outl	p1,a
	anl	p2,#0f0h
	jmp	X0053


; command 017h
rppc:	mov	r5,#6
	jmp	X0059


X0376:	mov	r5,#7
	mov	a,r7
	outl	p1,a
	anl	p2,#0f1h
	jmp	X0053


X037e:	mov	r5,#0
	mov	a,r7
	outl	p1,a
	anl	p2,#0f2h
	anl	p2,#0efh
	orl	p2,#10h
	orl	p2,#7fh


; command 019h
rdpdc:	mov	a,#8
	call	X00ec
	orl	p1,#0ffh
	mov	a,r7
	jb6	X039f
	anl	p2,#0bfh
	anl	p2,#0f3h
	anl	p2,#0efh
	call	X00b6
	jnc	X0300
	in	a,p1
	out	dbb,a
X039f:	jmp	X0055


; command 018h
rpstc:	mov	r0,#25h
	mov	r5,#0
	call	X03c9
	jt1	X03c0
	in	a,p1
	anl	a,#0ffh
X03ac:	out	dbb,a
	clr	f0
	orl	p2,#10h
	orl	p2,#7fh
X03b2:	jnibf	X03b6
	jmp	badc1x

X03b6:	jobf	X03b2
	mov	a,@r0
	anl	a,#2
	xch	a,@r0
	clr	f1
	out	dbb,a
	jmp	X005c

X03c0:	mov	a,#80h
	orl	a,@r0
	mov	@r0,a
	mov	a,#0ffh
	cpl	f1
	jmp	X03ac

X03c9:	orl	p1,#0ffh
	anl	p2,#0bfh
	anl	p2,#0f4h
	anl	p2,#0efh
	ret

X03d2:	orl	p1,#0ffh
	anl	p2,#0fch
	anl	p2,#0efh
	in	a,p1
	orl	p2,#10h
	orl	p2,#7fh
	ret


X03de:	mov	a,r5
	add	a,#X03e2 & 0ffh
	jmpp	@a

X03e2:	db	X03f5 & 0ffh
	db	X03ed & 0ffh
	db	X0308 & 0ffh
	db	X034c & 0ffh
	db	X0354 & 0ffh
	db	X035c & 0ffh
	db	X0376 & 0ffh
	db	X037e & 0ffh
	db	X03ef & 0ffh
	db	X03f1 & 0ffh
	db	X03f3 & 0ffh

X03ed:	jmp	X02d0

X03ef:	jmp	X01be

X03f1:	jmp	X01f3

X03f3:	jmp	X025c

x03f5:	mov	r0,#020h
	mov	a,#020h
	orl	a,@r0
	mov	@r0,a
	jmp	X005c

X03fd:	movp	a,@a
	ret

	fillto	0400h,000h

	end
