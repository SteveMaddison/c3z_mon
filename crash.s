;
; "Handle" fatal errors
;
; Steve Maddison, 25/02/2007
;

crash_message:	defm	"\n\n:-( \0"

crash_reg_header:
		defm	"A F  B C  D E  H L  SP\n\0"
crash:
		push	af
		push	hl
		ld	hl,crash_message
		call	console_outs
		call	error_str	; A should contain an error code
		call	console_outs
		ld	a,'\n'
		call	console_outb
		ld	hl,crash_reg_header
		call	console_outs
		pop	hl		; Original value of AF
		call	print_hex_16
		ld	a,' '
		call	console_outb
		push	bc
		pop	hl
		call	print_hex_16
		ld	a,' '
		call	console_outb
		push	de
		pop	hl
		call	print_hex_16
		ld	a,' '
		call	console_outb
		pop	hl
		call	print_hex_16
		ld	a,' '
		call	console_outb
		ld	hl,0
		add	hl,sp
		call	print_hex_16
		ld	a,'\n'
		call	console_outb
crash_stack_dump:
		ld	bc,stack_top+2
crash_stack_dump_loop:
		call	print_hex_16
		ld	a,':'
		call	console_outb
		ld	a,(hl)
		call	print_hex_8
		inc	hl
		ld	a,(hl)
		call	print_hex_8
		ld	a,'\n'
		call	console_outb
		inc	hl
		push	hl
		and	a
		sbc	hl,bc
		pop	hl
		jp	nz,crash_stack_dump_loop
		halt

