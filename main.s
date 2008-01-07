;
; Monitor program for the Cosam 3Z computer
;
; Steve Maddison, 12/02/2007
;

; *
; * The following code is location dependent - don't edit anything between
; * here and the end of the section (marked with a comment) unless you know
; * exactly what you're doing!
; *
init:		org	0		; program starts at 0x0000
		di			; turn off interrupts
		ld	sp,0xffff	; init stack pointer
		jp	start

title:		defm	"Cosam 3Z Monitor Program\0"
; As luck would have it, the above string pads up to 0x1f and the interrupt
; table defined in intr.s starts at 0x20 - exaclty where it must stay!
include		"intr.s"
; *
; * End of location-dependent section
; *

include		"uart.s"

start:
		call	intr_init
		call	uart_init

