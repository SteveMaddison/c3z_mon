;
; Monitor program for the Cosam 3Z computer
;
; Steve Maddison, 12/02/2007
;

init:		org	0			; program starts at 0x0000
		di				; turn off interrupts
		ld	sp,0xfffe
		jp	start

title:			defm	"Cosam 3Z Monitor\0"
version:		defm	"0.0.1\0"

; Include the various drivers...
include		"uart.s"
; Include utility functions...
include		"memory.s"
include		"float.s"
include		"calc.s"
include		"cli.s"
include		"print.s"
include		"crash.s"

; Labels to console device functions (in this case the UART)
console_outb:	equ	uart_tx
console_outs:	equ	uart_tx_str
console_inb:	equ	uart_rx

start:		
		ld	b,24
		ld	c,0
		ld	de,0x2020
		exx
		ld	b,24
		ld	c,0
		ld	de,0x1010
		call	float_sub
		halt

		call	uart_init

		; output banner to console
		ld	hl,title
		call	console_outs
		ld	a,' '
		call	console_outb
		ld	hl,version
		call	console_outs
		ld	a,'\n'
		call	console_outb

		call	mem_init

		; two newlines before command prompt
		ld	a,'\n'
		call	console_outb
		call	console_outb

		jp	cli_input

; Include memory location data...
include		"memmap.s"

