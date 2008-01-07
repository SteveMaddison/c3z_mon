;
; Printing routines
;
; Steve Maddison, 24/02/2007
;


print_float:
		ret

; In: BCDE
print_hex_32:
		push	hl
		push	bc
		pop	hl
		call	print_hex_16
		push	de
		pop	hl
		call	print_hex_16
		pop	hl
		ret

; In: HL
print_hex_16:
		push	af
		ld	a,h
		call	print_hex_8
		ld	a,l
		call	print_hex_8
		pop	af
		ret

; In: A
print_hex_8:	push	af		; save
		and	0xf0
		srl	a		; shift upper nibble >> lower nibble
		srl	a
		srl	a
		srl	a
		call	print_hex_4	; print upper nibble
		pop	af		; restore
		call	print_hex_4	; print lower nibble
		ret

print_hex_4:	and	0x0f			; lower nibble only
		cp	0x0a			; check for A-F
		jp	c,print_hex_4_numeric
		add	a,39			; offset between chars '0' and 'a'
print_hex_4_numeric:
		add	a,'0'
		call	console_outb
		ret

; Print signed 16-bit integer in HL
print_int_16:	push	af
		push	bc
		push	de
		; most significant bit of HL is set, number is negative
		bit	7,h
		jp	z,print_int_16_positive
		; print a "-" and get the absolute value of HL
		ld	a,'-'
		call	console_outb
		call	int_2s_comp_16
print_int_16_positive:
		; Test for special case of HL = 0
		ld	a,h
		or	l
		jp	nz,print_int_16_non_zero
		ld	a,'0'
		call	console_outb
		jp	print_int_16_end
print_int_16_non_zero:
		ld	de,10	; Initialise divisor of 10
		xor	a	; push a zero onto the stack
		push	af
		push	hl	; set up for division subroutine
		pop	bc
print_int_16_div_loop:
		; Keep dividing by 10 until there's nothing left, pushing
		; the character representing the remainder to the stack
		; each iteration. Yes, pushing F to the stack is wasteful
		; but it saves a lot of work here.
		call	int_div_16
		ld	a,l
		add	a,'0'
		push	af
		ld	a,b	; check for end case: BC = 0
		or	c
		jp	nz,print_int_16_div_loop
print_int_16_output:
		; Pop the first character in order to simplify the loop below.
		pop	af
print_int_16_output_loop:
		; Keep printing and poping until we hit the zero we pushed
		; during initialisation.
		call	console_outb
		pop	af
		cp	0
		jp	nz,print_int_16_output_loop
print_int_16_end:
		pop	de
		pop	bc
		pop	af
		ret

print_int_8:
		push	hl
		ld	h,0
		ld	l,a
		call	print_int_16
		pop	hl
		ret

