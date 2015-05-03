; I/O ports

dbbout	equ	000h	; write to DBB output buffer, set/reset OBF flag
unkp10	equ	010h	; port 10h, unknown (maybe used in IOC-III?)
iocbusy	equ	020h	; set/reset IOC busy flag
setcd	equ	030h	; set F1 command/data flag: status to IPB/IPC
clrcd	equ	040h	; reset F1 command/data flag: data to IPB/IPC
strtbel	equ	050h	; start bell timer

miscout	equ	060h	; write to miscellaneous output register
bellen	equ	001h	; bell enable
mastint	equ	002h	; master interrupt
unused4	equ	004h	; unknown output (maybe used in IOC-III?)
dmaena	equ	020h	; DMA enable

miscin	equ	080h	; read miscellaneous data
hz50	equ	001h	; 50Hz if 1
flppres	equ	002h	; floppy present if 1
belltmr	equ	004h	; bell timer
localmd	equ	008h	; local mode if 1 (vs online, debug)
unkin10	equ	010h	; unconnected input (maybe used in IOC-III?)
diagmd	equ	020h	; diag mode if 1 (vs online, local)
testpt	equ	040h	; test point, J18-10
kbpres	equ	080h	; keyboard present if 1


kbddat	equ	090h	; read keyboard data
kbdstat	equ	092h	; read keyboard status

dbbstat	equ	0a0h	; read DBB status (flags)
dbbin	equ	0b0h	; read DBB input buffer, reset IBF flag

; 8271 floppy disk controller
fdcstat	equ	0c0h	; FDC status (in)
fdccmd	equ	0c0h	; FDC command (out)
fdcrslt	equ	0c1h	; FDC result (in)
fdcparm	equ	0c1h	; FDC parameter (out)
fdcrst	equ	0c2h	; FDC reset (out)

; 8275 CRT controller
crtcmd	equ	0d1h	; CRTC command (out)
crtparm	equ	0d0h	; CRTC parameter (in/out)

crtstat	equ	0d1h	; CRTC status (in)

crtsie	equ	040h	; CRTC status - interrupt enable
crtsir	equ	020h	; CRTC status - interrupt request
crtslp	equ	010h	; CRTC status - light pen loaded
crtcic	equ	008h	; CRTC status - improper command
crtcve	equ	004h	; CRTC status - video enabled
crtcdu	equ	002h	; CRTC status - DMA underrun
crtcfo	equ	001h	; CRTC status - FIFO overrun

crtrst	equ	000h	; CRTC reset command
crtstrt	equ	020h	; CRTC start display command (params in low 5 bits)
crteni	equ	0a0h	; CRTC enable interrupt command


; 8253 interval timer
trefrsh	equ	0e0h	; used for DRAM refresh, causes DMA request 0
			;   clock: 2 MHz  gate: always enabled
thoriz	equ	0e1h	; horizontal timer
			;   clock: timer1 output  gate: hblank from CRTC
tbell	equ	0e2h	; bell
			;   clock: timer0 output (64.5 kHz)  gate: out to strtbel
timermd	equ	0e3h

; timermd bits 7..6:
tmsrfsh	equ	000h
tmshorz	equ	040h
tmsbell	equ	080h

; timermd bits 5..3:
tminttc	equ	000h	; interrupt on terminal count
tonesht	equ	002h	; one-shot
trategn	equ	004h	; rate generator
tsqwrg	equ	008h	; square wave rage generator
tswtrb	equ	00ah	; software triggered strobe
thwstb	equ	00ch	; hardware triggered strobe

; timermd bits 0:
tbinary	equ    000h
tbcd	equ    001h

; timermd bits 5..4:
trllat	equ	000h	; latch operation
trmsb	equ	020h	; read/load most significant byte only
trlsb	equ	010h	; read/load least significant byte only
trboth	equ	030h	; read/load least sig, then most sig byte


; 8257 DMA controller (alt. 8237 DMA controller)
; DMA channel 0 - used for DRAM refresh
dmac0a	equ	0f0h	; address (in/out)
dmac0tc	equ	0f1h	; terminal count (in/out)

; DMA channel 1 - floppy disk controller
dmac1a	equ	0f2h	; address (in/out)
dmac1tc	equ	0f3h	; terminal count (in/out)

; DMA channel 2 - CRT controller
dmac2a	equ	0f4h	; address (in/out)
dmac2tc	equ	0f5h	; terminal count (in/out)

; DMA channel 3, used to reload channel 2 for scrolling
dmac3a	equ	0f6h	; address (in/out)
dmac3tc	equ	0f7h	; terminal count (in/out)

dmastat	equ	0f8h	; DMA status (in)
dmamode	equ	0f8h	; DMA mode set (out, 8257), command (out, 8237 only)

dmawreq	equ	0f9h	; DMA write request register (out, 8237 only)
dmawsmr	equ	0fah	; DMA write single masig reg bit (out, 8237 only)
dmawmod	equ	0fbh	; DMA write mode register (out, 8237 only)
dmaclbp	equ	0fch	; DMA clear byte pointer FF (out, 8237 only)
dmactmp	equ	0fdh	; DMA temporary register (in, 8237 only)
dmamclr	equ	0fdh	; DMA master clear (out, 8237 only)
dmawamr	equ	0ffh	; DMA write all mask register bits (out, 8237 only)

; 8257 mode set bits (NOT the same as 8237 mode register bits):
dautold	equ	080h
dtcstop	equ	040h
dextwrt	equ	020h
drotpri	equ	010h

dmaen3	equ	008h
dmaen2	equ	004h
dmaen1	equ	002h
dmaen0	equ	001h
