;
; Monitor program for the Cosam 3Z computer
;
; Steve Maddison, 12/02/2007
;

init:		org	0			; program starts at 0x0000
		di				; turn off interrupts
		ld	sp,0x0000		; first push will make this 0xfffe
		jp	start

title:		defm	"Cosam 3Z Monitor\0"
version:	defm	"0.0.1\0"

; Pad to 0x38 for interrupt
padding:	defm	"                          "
include		"intr.s"

; Include the various drivers...
include		"uart.s"
include		"ide.s"
include		"slip.s"
include		"ip.s"
include		"socket.s"
include		"icmp.s"
include		"pseudo.s"
include		"udp.s"
; Include utility functions...
include		"device.s"
include		"fs.s"
include		"memory.s"
include		"int.s"
include		"float.s"
include		"cli.s"
include		"builtin.s"
include		"print.s"
include		"crash.s"
include		"error.s"
include		"string.s"
include		"ll.s"

; Labels to console device functions (in this case the UART)
console_outb:	equ	uart_tx
console_outs:	equ	uart_tx_str
console_inb:	equ	uart_rx

;null_func:	ret

;console_outb:	equ	null_func
;console_outs:	equ	null_func
;console_inb:	equ	null_func


start:		
		call	mem_init
		call	dev_init

		call	uart_init

		; output banner to console
;		ld	hl,title
;		call	console_outs
;		ld	a,' '
;		call	console_outb
;		ld	hl,version
;		call	console_outs
;		ld	a,'\n'
;		call	console_outb
;		call	console_outb

		;call	ide_init
		call	slip_init
		call	ip_init
		call	sock_init

		; Not yet...
		;call	intr_init

		ld	a,8
		ld	bc,0x0a00
		ld	de,0x0002
		call	icmp_tx_echo

;		ld	a,0x99
;loop_99:
;		ld	b,16
;		call	uart_tx
;		djnz	loop_99

bla:
		jp	bla

		; two newlines before command prompt
		;ld	a,'\n'
		;call	console_outb
		;call	console_outb

		;ld	de,ide_dev_name_master
		;call	fs_create

		;jp	cli_input

; Include memory location data...
include		"memmap.s"

