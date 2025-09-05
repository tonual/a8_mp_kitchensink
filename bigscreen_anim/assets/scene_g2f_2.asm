/***************************************/
/*  Use MADS http://mads.atari8.info/  */
/*  Mode: DLI (char mode)              */
/***************************************/

	icl "scene_g2f_2.h"

	org $f0

fcnt	.ds 2
fadr	.ds 2
fhlp	.ds 2
cloc	.ds 1
regA	.ds 1
regX	.ds 1
regY	.ds 1

WIDTH	= 32
HEIGHT	= 30

; ---	BASIC switch OFF
	org $2000\ mva #$ff portb\ rts\ ini $2000

; ---	MAIN PROGRAM
	org $2000
ant	dta $C4,a(scr)
	dta $84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84,$84
	dta $84,$84,$84,$84,$84,$84,$84,$04,$04,$04,$84,$04,$04
	dta $41,a(ant)

scr	ins "scene_g2f_2.scr"

	.ds 0*40

	.ALIGN $0400
fnt	ins "scene_g2f_2.fnt"

	ift USESPRITES
	.ALIGN $0800
pmg	.ds $0300
	ift FADECHR = 0
	SPRITES
	els
	.ds $500
	eif
	eif

main
; ---	init PMG

	ift USESPRITES
	mva >pmg pmbase		;missiles and players data address
	mva #$03 pmcntl		;enable players and missiles
	eif

	lda:cmp:req $14		;wait 1 frame

	sei			;stop IRQ interrupts
	mva #$00 nmien		;stop NMI interrupts
	sta dmactl
	mva #$fe portb		;switch off ROM to get 16k more ram

	mwa #NMI $fffa		;new NMI handler

	mva #$c0 nmien		;switch on NMI+DLI again

	ift CHANGES		;if label CHANGES defined

_lp	lda trig0		; FIRE #0
	beq stop

	lda trig1		; FIRE #1
	beq stop

	lda consol		; START
	and #1
	beq stop

	lda skctl
	and #$04
	bne _lp			;wait to press any key; here you can put any own routine

	els

null	jmp DLI.dli1		;CPU is busy here, so no more routines allowed

	eif


stop
	mva #$00 pmcntl		;PMG disabled
	tax
	sta:rne hposp0,x+

	mva #$ff portb		;ROM switch on
	mva #$40 nmien		;only NMI interrupts, DLI disabled
	cli			;IRQ enabled

	rts			;return to ... DOS

; ---	DLI PROGRAM

.local	DLI

	?old_dli = *

	ift !CHANGES

dli1	lda trig0		; FIRE #0
	beq stop

	lda trig1		; FIRE #1
	beq stop

	lda consol		; START
	and #1
	beq stop

	lda skctl
	and #$04
	beq stop

	lda vcount
	cmp #$02
	bne dli1

	:3 sta wsync

	sta wsync		;line=0
	sta wsync		;line=1
	sta wsync		;line=2
	sta wsync		;line=3
	sta wsync		;line=4
	sta wsync		;line=5
c18	lda #$0E
	sta wsync		;line=6
	sta color0
	sta color1
	mwa #null null+1
	jmp null

	eif

dli_start

dli2
	sta regA
	lda >fnt+$400*$01
	sta wsync		;line=8
	sta chbase
	DLINEW dli3 1 0 0

dli3
	sta regA
	lda >fnt+$400*$02
	sta wsync		;line=16
	sta chbase
	DLINEW dli4 1 0 0

dli4
	sta regA
	lda >fnt+$400*$03
	sta wsync		;line=24
	sta chbase
	sta wsync		;line=25
	sta wsync		;line=26
	sta wsync		;line=27
c19	lda #$08
	sta wsync		;line=28
	sta color0
	sta color1
	DLINEW dli5 1 0 0

dli5
	sta regA
	stx regX
	sty regY
	lda >fnt+$400*$04
c20	ldx #$92
c21	ldy #$0E
	sta wsync		;line=32
	sta chbase
	stx color0
	sty color1
	DLINEW dli6 1 1 1

dli6
	sta regA
	lda >fnt+$400*$05
	sta wsync		;line=40
	sta chbase
	DLINEW dli7 1 0 0

dli7
	sta regA
	lda >fnt+$400*$06
	sta wsync		;line=48
	sta chbase
	sta wsync		;line=49
c22	lda #$08
	sta wsync		;line=50
	sta color1
	DLINEW dli8 1 0 0

dli8
	sta regA
	lda >fnt+$400*$07
	sta wsync		;line=56
	sta chbase
	DLINEW dli9 1 0 0

dli9
	sta regA
	lda >fnt+$400*$08
	sta wsync		;line=64
	sta chbase
	DLINEW dli10 1 0 0

dli10
	sta regA
	lda >fnt+$400*$09
	sta wsync		;line=72
	sta chbase
	sta wsync		;line=73
	sta wsync		;line=74
	sta wsync		;line=75
c23	lda #$0E
	sta wsync		;line=76
	sta color1
	DLINEW dli11 1 0 0

dli11
	sta regA
	lda >fnt+$400*$0A
	sta wsync		;line=80
	sta chbase
	DLINEW dli12 1 0 0

dli12
	sta regA
	lda >fnt+$400*$0B
	sta wsync		;line=88
	sta chbase
	DLINEW dli13 1 0 0

dli13
	sta regA
	lda >fnt+$400*$0C
	sta wsync		;line=96
	sta chbase
	sta wsync		;line=97
	sta wsync		;line=98
	sta wsync		;line=99
	sta wsync		;line=100
	sta wsync		;line=101
c24	lda #$08
	sta wsync		;line=102
	sta color1
	DLINEW dli14 1 0 0

dli14
	sta regA
	lda >fnt+$400*$0D
	sta wsync		;line=104
	sta chbase
	sta wsync		;line=105
	sta wsync		;line=106
	sta wsync		;line=107
	sta wsync		;line=108
	sta wsync		;line=109
c25	lda #$0E
	sta wsync		;line=110
	sta color1
	DLINEW dli15 1 0 0

dli15
	sta regA
	lda >fnt+$400*$0E
	sta wsync		;line=112
	sta chbase
	DLINEW dli16 1 0 0

dli16
	sta regA
	stx regX
	lda >fnt+$400*$0F
c26	ldx #$08
	sta wsync		;line=120
	sta chbase
	stx color1
	DLINEW dli17 1 1 0

dli17
	sta regA
	lda >fnt+$400*$10
	sta wsync		;line=128
	sta chbase
	sta wsync		;line=129
	sta wsync		;line=130
	sta wsync		;line=131
	sta wsync		;line=132
	sta wsync		;line=133
c27	lda #$0E
	sta wsync		;line=134
	sta color1
	DLINEW dli18 1 0 0

dli18
	sta regA
	lda >fnt+$400*$11
	sta wsync		;line=136
	sta chbase
	DLINEW dli19 1 0 0

dli19
	sta regA
	lda >fnt+$400*$12
	sta wsync		;line=144
	sta chbase
	DLINEW dli20 1 0 0

dli20
	sta regA
	lda >fnt+$400*$13
	sta wsync		;line=152
	sta chbase
	sta wsync		;line=153
	sta wsync		;line=154
	sta wsync		;line=155
c28	lda #$08
	sta wsync		;line=156
	sta color1
	DLINEW dli21 1 0 0

dli21
	sta regA
	lda >fnt+$400*$14
	sta wsync		;line=160
	sta chbase
	DLINEW dli22 1 0 0

dli22
	sta regA
	lda >fnt+$400*$15
	sta wsync		;line=168
	sta chbase
	DLINEW dli23 1 0 0

dli23
	sta regA
	lda >fnt+$400*$16
	sta wsync		;line=176
	sta chbase
	DLINEW dli24 1 0 0

dli24
	sta regA
	lda >fnt+$400*$17
	sta wsync		;line=184
	sta chbase
	DLINEW dli25 1 0 0

dli25
	sta regA
	stx regX
	sty regY
	lda >fnt+$400*$18
c29	ldx #$D6
c30	ldy #$08
	sta wsync		;line=192
	sta chbase
	stx colbak
	sty color0
	DLINEW dli26 1 1 1

dli26
	sta regA
	lda >fnt+$400*$19
	sta wsync		;line=224
	sta chbase

	lda regA
	rti

.endl

; ---

CHANGES	= 0
FADECHR	= 0

SCHR	= 127

; ---

.proc	NMI

	bit nmist
	bpl VBL

	jmp DLI.dli2
dliv	equ *-2

VBL
	sta regA
	stx regX
	sty regY

	sta nmist		;reset NMI flag

	mwa #ant dlptr		;ANTIC address program

	mva #@dmactl(narrow|dma|lineX1|players|missiles) dmactl	;set new screen width

	inc cloc		;little timer

; Initial values

	lda >fnt+$400*$00
	sta chbase
c14	lda #$94
	sta colbak
c15	lda #$08
	sta color0
	sta color1
c16	lda #$D6
	sta color2
	sta color3
	lda #$03
	sta chrctl
	lda #$31
	sta gtictl
s0	lda #$03
	sta sizep0
	sta sizep1
	sta sizep2
	sta sizep3
s1	lda #$FF
	sta sizem
x1	lda #$31
	sta hposp0
x2	lda #$51
	sta hposp1
x3	lda #$71
	sta hposp2
x4	lda #$91
	sta hposp3
x5	lda #$B1
	sta hposm0
x6	lda #$B9
	sta hposm1
x7	lda #$C1
	sta hposm2
x8	lda #$C9
	sta hposm3
c17	lda #$26
	sta colpm0
	sta colpm1
	sta colpm2
	sta colpm3

	mwa #DLI.dli2 dliv	;set the first address of DLI interrupt
	mwa #DLI.dli1 null+1	;synchronization for the first screen line

;this area is for yours routines

quit
	lda regA
	ldx regX
	ldy regY
	rti

.endp

; ---
	run main
; ---

	opt l-

.MACRO	SPRITES
missiles
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
player0
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
player1
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
player2
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
player3
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
.ENDM

USESPRITES = 0

.MACRO	DLINEW
	mva <:1 NMI.dliv
	ift [>?old_dli]<>[>:1]
	mva >:1 NMI.dliv+1
	eif

	ift :2
	lda regA
	eif

	ift :3
	ldx regX
	eif

	ift :4
	ldy regY
	eif

	rti

	.def ?old_dli = *
.ENDM

