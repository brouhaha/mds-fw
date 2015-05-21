; RAM, 4000h..5fffh

rambase	equ	04000h

	org	rambase
cursor:	ds	2	; pointer into screen buffer for cursor loc

	org	041eah
d41ea:	ds	2
d41ec:	ds	1	; not sure of size
	ds	7
d41f4:	ds	1
	ds	2
moshad	ds	1	; RAM shadow of miscout register
	ds	8

; 04200h through 04effh: disk data buffer
; also used to save screen when showing function key help
databf:	ds	26*128

crtrows	equ	25
crtcols	equ	80
crtsize	equ	crtrows*crtcols

	org	05230h
scrbeg:	ds	crtsize	; start of screen buffer
scrend:			; ends at 05a00h (last byte used 059ffh)

cmdtab:	ds	32*2	; pointer to handlers for IOC commands

	ds	62	; unused, available

altcop:	ds	2	; alternate console output case table pointer
			; normally zero

coflag:	ds	128	; conout flags - set using ESC X sequence

r5a80:	equ	coflag+000h	; use 8 bit flag, mask off MSB unless true
r5a81:	equ	coflag+001h	; pause flag
r5a82:	equ	coflag+002h	; visible control flag

r5af0:	equ	coflag+070h	; wraparound characteristics
r5af1:	equ	coflag+071h	; CRT parititions
r5af2:	equ	coflag+072h	; cursor addressing format
r5af3:	equ	coflag+073h	; alternate keyboard table ptr, high byte
r5af4:	equ	coflag+074h	; unlock memory write flag (set to 024h)
crsrfmt	equ	coflag+075h	; cursor blinking format
r5af6:	equ	coflag+076h	; number of lines between pause
r5af7:	equ	coflag+077h	; blankout character (clear scren/line)
r5af8:	equ	coflag+078h	; marker character
r5af9:	equ	coflag+079h	; keyboard buffer size
r5afa:	equ	coflag+07ah	; keyboard buffer last flag


; conout case numbers
ccdisp	equ	0	; output the character
ccesc	equ	1	; escape - look up next char in escape case # table
ccbell	equ	2	; ring bell
ccnop	equ	3	; do nothing
ccflag	equ	4	; set user flag (ESC X function)
ccmark	equ	5	; MARK: display visible marker set by ESC X x
ccspc	equ	6	; output a space
ccrubo	equ	7	; rubout: cursor left wrap, then blank char
cclit	equ	8	; display next character literally
ccmsb0	equ	9	; display next char with top bit masked off
ccmsb1	equ	10	; display next char with top bit turned on (attribute)
ccculf	equ	11	; cursor left freeze
cccuuf	equ	12	; cursor up freeze
cccurf	equ	13	; cursor right freeze
cccudf	equ	14	; cursor down freeze
ccculr	equ	15	; cursor left roll
cccuur	equ	16	; cursor up roll
cccurr	equ	17	; cursor right roll
cccudr	equ	18	; cursor down roll
ccculw	equ	19	; cursor left wrap
cccuuw	equ	20	; cursor up wrap
cccurw	equ	21	; cursor right wrap
cccudw	equ	22	; cursor down wrap
ccgoxy	equ	23	; cursor go to coordinates (ESC Y function)
ccgopa	equ	24	; cursor go to partition (ESC M function)
ccrest	equ	25	; restore cursor to value before last 23 function
ccret	equ	26	; cariage return, go to start of current line
cchome	equ	27	; home the cursor within partition
ccclsh	equ	28	; clear screen and home cursor
cccls	equ	29	; clear screen but don't home cursor
cccles	equ	30	; clear from begining of this line to end of screen
ccceos	equ	31	; clear to end of screen
ccclrl	equ	32	; clear entire line
ccceol	equ	32	; clear to end of line
ccidln	equ	33	; insert and delete line
ccidch	equ	34	; insert and delete character
ccuser	equ	128	; start of user-defined cases


; 5b00-5bff - conout primary case numbers
r5b00	ds	256

r5b20	equ	r5b00+020h
r5b80	equ	r5b00+080h


; 5c00-5cff - conout escape case numbers
r5c00	ds	256

r5c41	equ	r5c00+'A'
r5c61	equ	r5c00+'a'
r5c80	equ	r5c00+080h


; 5d00-5dff - keyboard cases table
	ds	256


; 5e00-5eff - keyboard input queue
	ds	256


r5f00	ds	52		; pointers to lines in screen buffer

r5f34:	ds	1		; index into keyboard queue of next key to
				; send to CPU
	ds	1		; index into keyboard queue of next empty
				; loc to fill from CPU

r5f36:	ds	2		; pointer to mem loc in screen buf of cursor 

r5f38:	ds	1
r5f39:	ds	1
r5f3a:	ds	2
r5f3c:	ds	2

nrolls:	ds	1

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
r5ff5:	ds	2		; code - output C reg to console
r5ff7:				; code, unknown size

