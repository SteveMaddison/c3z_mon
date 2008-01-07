;
; Built-in CLI commands
;
; Steve Maddison, 18/03/2007
;

builtin_cmd_echo:	defm	"echo\0"
builtin_cmd_ver:	defm	"ver\0"

builtin_echo:
		pop	bc
		pop	hl
builtin_echo_loop:
		ld	a,h
		or	l
		jp	z,builtin_echo_end
		call	console_outs
		pop	hl
		ld	a,h
		or	l
		jp	z,builtin_echo_end
		ld	a,' '
		call	console_outb
		jp	builtin_echo_loop
builtin_echo_end:
		ld	a,'\n'
		call	console_outb
		xor	a
		push	bc
		ret

builtin_ver:
		ld	hl,version
		call	console_outs
		ld	a,'\n'
		call	console_outb

		xor	a
		ret

