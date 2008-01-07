;
; Monitor program for the Cosam 3Z computer
;
; Steve Maddison, 12/02/2007
;

init:		org	0		; program starts at 0x0000
		di			; turn off interrupts
		ld	sp,0xffff	; init stack pointer
		jp	start

title:		defm	"Cosam 3Z Monitor Program\0"
version:	defm	"0.0.1\0"

; Include the various drivers...
include		"uart.s"
; Include utility functions...
include		"calc.s"
include		"cli.s"

; Labels to console device functions (in this case the UART)
console_outb:	equ	uart_tx
console_outs:	equ	uart_tx_str
console_inb:	equ	uart_rx

start:		call	uart_init

		ld	hl,title
		call	console_outs
		ld	a,' '
		call	console_outb
		ld	hl,version
		call	console_outs

		ld	a,'\n'
		call	console_outb
		call	console_outb

		jp	cli_input

; Include memory location data...
include		"memmap.s"

