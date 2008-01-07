;
; Command Line Interface
;
; Steve Maddison, 15/02/2007
;

cli_prompt:	defm	"> \0"

cli_input:	ld	hl,cli_prompt		; output prompt
		call	console_outs
		
		ld	bc,cli_buffer		; BC = current position in buffer
		push	bc
		pop	de			; DE = pointers to after end of input

cli_input_loop:
		call	console_inb		; get a char
; if newline
		cp	'\n'
		jp	z,cli_input_done
; elsif backspace
		cp	0x08
		jp	nz,cli_input_not_backspace
		call	cli_check_buffer_empty
		jp	z,cli_input_bell
		dec	bc
		dec	de
cli_input_not_backspace:
; elsif del
		cp	0x10
		jp	nz,cli_input_not_del
		call	cli_check_buffer_empty
		jp	z,cli_input_bell
		call	cli_check_buffer_end
		; HL now = number of chars to buffer end
		jp	z,cli_input_bell
		push	bc	; save
		push	de
		; register swapery: HL -> BC -> DE and BC+1 -> HL
		push	bc
		inc	bc
		push	bc
		push	hl
		pop	bc
		pop	hl
		pop	de
		ldir		; move block
		pop	de	; restore original values
		pop	bc
		dec	de	; string is shortened
cli_input_not_del:
; elsif esc
		cp	0x1b
		jp	nz,cli_input_not_esc
		call	console_inb		; get next char of the escape code
		cp	'['
		jp	z,cli_input_bell	; unsupported escape code
		call	console_inb		; fetch char after ESC-[
		cp	'D'			; left arrow
		jp	z,cli_input_cursor_left
		cp	'C'			; right arrow
		jp	z,cli_input_cursor_right
		jp	cli_input_bell
cli_input_cursor_left:
		call	cli_check_buffer_start
		jp	z,cli_input_loop
		dec	bc
cli_input_cursor_right:
		call	cli_check_buffer_end
		jp	z,cli_input_loop
		inc	bc
cli_input_not_esc:
; elsif character < 0x20
		cp	0x20
		jp	c,cli_input_loop
; else... Character has no special meaning, so add it to the buffer.
		call	cli_check_buffer_full
		jp	z,cli_input_bell
; If we're not at the end of the buffer, we need to make space first.
		call	cli_check_buffer_end
		; HL now = number of chars to buffer end
		jp	z,cli_input_add
		push	bc	; save
		; register swapery: HL -> BC and DE-1 -> HL
		; (DE already points just after end of input)
		push	de
		push	hl
		pop	bc
		pop	hl
		dec	hl
		lddr		; move block
		pop	bc	; restore value
cli_input_add:
		ld	(bc),a			; save byte to buffer
		inc	bc			; increment pointers
		inc	de
		jp	cli_input_echo

cli_input_bell:
		ld	a,0x07
cli_input_echo:
		call	console_outb
		jp	cli_input_loop

cli_input_done:
		xor	a			; terminate string with '\0'
		ld	(de),a
		ld	a,'\n'			; echo newline
		call	console_outb
		; process command
		jp	cli_input

; Returns with zero flag set if buffer is empty
cli_check_buffer_empty:
		ld	hl,cli_buffer
		sbc	hl,bc
		ret

; Returns with zero flag set if we're at the end of the input
; HL = number of bytes to end of input
cli_check_buffer_end:
		push	de
		pop	hl
		sbc	hl,bc
		ret

; Returns with zero flag set if buffer is full
; HL = number of bytes left in buffer
cli_check_buffer_full:
		ld	hl,cli_buffer_end
		sbc	hl,bc
		ret

; Returns with zero flag set if we're at the start of the input
; HL = current position in buffer
cli_check_buffer_start:
		ld	hl,cli_buffer
		sbc	hl,bc
		ret

