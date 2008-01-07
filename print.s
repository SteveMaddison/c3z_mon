;
; Printing routines
;
; Steve Maddison, 24/02/2007
;

print_digits:	defm	"0123456789abcdef"

print_hex_16:
		push	af
		ld	a,h
		call	print_hex_8
		ld	a,l
		call	print_hex_8
		pop	af
		ret

print_hex_8:	push	af
		and	0xf0
		srl	a
		srl	a
		srl	a
		srl	a
		call	print_hex_4
		pop	af
		call	print_hex_4
		ret

print_hex_4:	push	hl
		push	bc
		and	0x0f
		ld	hl,print_digits
		ld	b,0
		ld	c,a
		add	hl,bc
		ld	a,(hl)
		call	console_outb
		pop	bc
		pop	hl
		ret

; Print signed 16-bit integer in HL
print_int:	push	af
		push	bc
		push	de
		; most significant bit of HL is set, number is negative
		bit	7,h
		jp	z,print_int_positive
		; print a "-" and get the absolute value of HL
		ld	a,'-'
		call	console_outb
		call	calc_2s_comp_16
print_int_positive:
		; Test for special case of HL = 0
		ld	a,h
		or	l
		jp	nz,print_int_non_zero
		ld	a,'0'
		call	console_outb
		jp	print_int_end
print_int_non_zero:
		ld	de,10	; Initialise divisor of 10
		xor	a	; push a zero onto the stack
		push	af
		push	hl	; set up for division subroutine
		pop	bc
print_int_div_loop:
		; Keep dividing by 10 until there's nothing left, pushing
		; the character representing the remainder to the stack
		; each iteration.
		call	calc_int_div_16
		ld	a,l
		add	a,'0'
		push	af
		ld	a,b	; check for end case: BC = 0
		or	c
		jp	nz,print_int_div_loop
print_int_output:
		; Pop the first character in order to simplify the loop below.
		pop	af
print_int_output_loop:
		; Keep printing and poping until we hit the zero we pushed
		; during initialisation.
		call	console_outb
		pop	af
		cp	0
		jp	nz,print_int_output_loop
print_int_end:
		pop	de
		pop	bc
		pop	af
		ret

