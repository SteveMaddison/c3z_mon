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
; if enter
		cp	0x0d
		jp	z,cli_input_done
; elsif backspace
		cp	0x08
		jp	nz,cli_input_not_backspace
		call	cli_check_buffer_start
		jp	z,cli_input_bell
		call	cli_check_buffer_end
		; Whatever happens, cursor needs to go back one
		dec	bc			; dec will not affect zero flag
		jp	nz,cli_input_remove	; if not at end, shift chars left
		dec	de			; otherwise, just update the pointer
		jp	cli_input_echo
cli_input_not_backspace:
; elsif del
		cp	0x7f
		jp	nz,cli_input_not_del
		call	cli_check_buffer_empty
		jp	z,cli_input_bell
		call	cli_check_buffer_end
		; HL now = number of chars to buffer end
		jp	z,cli_input_bell
cli_input_remove:
		; common code for backspace and delete
		push	bc	; save
		push	de
		; register swapery: HL -> BC -> DE and BC+1 -> HL
		push	bc
		push	bc
		push	hl
		pop	bc
		pop	hl
		inc	hl
		pop	de
		ldir		; move block
		pop	de	; restore original values
		pop	bc
		dec	de	; string is shortened
		jp	cli_input_echo
cli_input_not_del:
; elsif esc
		cp	0x1b
		jp	nz,cli_input_not_esc
		call	console_inb		; get next char of the escape code
		cp	'['
		jp	nz,cli_input_bell	; unsupported escape code
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
		jp	cli_input_loop
cli_input_cursor_right:
		call	cli_check_buffer_end
		jp	z,cli_input_loop
		inc	bc
		jp	cli_input_loop
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
		push	de
		; register swapery: HL -> BC and DE-1 -> HL
		; (DE already points just after end of input)
		push	de
		push	hl
		pop	bc
		pop	hl
		dec	hl
		lddr		; move block
		pop	de	; restore values
		pop	bc
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
		ld	a,0		; terminate string
		ld	(de),a
		ld	a,'\n'		; echo newline
		call	console_outb

		; Split command line into arguments.
cli_parse:
		ld	hl,0x0000	; mark end of arguments
		push	hl
		push	de		; address of "previous" character
		pop	hl		; address of current character
		dec	hl		; point to byte before '\0'
		ld	bc,0x00ff	; B = number of arguments,
					; C = last quote delimeter seen
cli_parse_loop:
		push	hl		; Have we reached start of buffer?
		push	bc
		ld	bc,cli_buffer
		and	a
		sbc	hl,bc
		pop	bc
		pop	hl
		jp	nc,cli_parse_check_char
		ld	a,(de)
		cp	0
		jp	z,cli_parse_end
		push	de		; Save argument address
		inc	b
		jp	cli_parse_end
cli_parse_check_char:
		ld	a,(hl)
cli_parse_check_quote:
		cp	c		; Does this character match the
					; quote we've already seen?
		jp	nz,cli_parse_no_quote_match
		dec	hl		; Check for escape
		ld	a,(hl)
		cp	'\\'
		jp	z,cli_parse_no_quote_match
		ld	(hl),0		; We're at the start of a quoted
		push	de		; argument, so save its address.
		inc	b
		ld	c,0xff		; Reset the "current quote" value.
		dec	de
		jp	cli_parse_loop
cli_parse_no_quote_match:
		cp	'"'		; Found a new quote?
		jp	z,cli_parse_quote
		cp	'''
		jp	z,cli_parse_quote
		jp	cli_parse_not_quote
cli_parse_quote:
		dec	de		; Point DE to the quote itself
		dec	hl		; Check for escape
		ld	a,(hl)
		cp	'\\'
		jp	z,cli_parse_loop
		ld	a,(de)		; Quote is not escaped, so it must
		ld	c,a		; mark the end of an argument.
		xor	a
		ld	(de),a
		jp	cli_parse_loop
cli_parse_not_quote:
		cp	' '		; Is character a space?
		jp	nz,cli_parse_skip
		ld	a,c		; Are we in the middle of a quoted argument?
		cp	0xff
		jp	nz,cli_parse_skip
		ld	(hl),0		; Terminate argument here
		ld	a,(de)		; Was pervious char also a space? If so,
		cp	0		; we've already saved this argument's address.
		jp	z,cli_parse_skip
		push	de		; DE now points to first non-space
					; char after one or more spaces.
		inc	b
cli_parse_skip:
		dec	hl		; Rinse and repeat
		dec	de
		jp	cli_parse_loop

cli_parse_end:
		ld	a,c		; Were we still looking for a quote?
		cp	0xff
		jp	z,cli_parse_ok
		ld	hl,error_str_delimeter
		call	console_outs
		ld	a,'\n'
		call	console_outb
		pop	hl		; remove end marker from stack
		jp	cli_input
cli_parse_ok:
		pop	hl
		ld	a,h
		or	l
		jp	z,cli_parse_done
		call	console_outs
		ld	a,'\n'
		call	console_outb
		jp	cli_parse_ok
cli_parse_done:
		jp	cli_input

; Returns with zero flag set if buffer is empty
cli_check_buffer_empty:
		ld	hl,cli_buffer
		and	a
		sbc	hl,de
		ret

; Returns with zero flag set if we're at the end of the input
; HL = number of bytes to end of input
cli_check_buffer_end:
		push	de
		pop	hl
		and	a
		sbc	hl,bc
		ret

; Returns with zero flag set if buffer is full
; HL = number of bytes left in buffer
cli_check_buffer_full:
		ld	hl,cli_buffer_end
		and	a
		sbc	hl,de
		ret

; Returns with zero flag set if we're at the start of the input
; HL = current position in buffer
cli_check_buffer_start:
		ld	hl,cli_buffer
		and	a
		sbc	hl,bc
		ret

