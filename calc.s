;
; Mathematical subroutines
;
; Steve Maddison, 12/02/2007
;


; Name: calc_int_div_8
; Desc:	Divide two 8-bit integers with 8-bit result
; In:	E = dividend, C = divisor
; Out:	A = quotient, B = remainder
calc_int_div_8:
		push	af
		push	de
		xor	a
		ld	b,8
calc_int_div_8_loop:
		rl	e
		rla
		sub	c
		jr	nc,calc_int_div_8_no_add
		add	a,c
calc_int_div_8_no_add:
		djnz	calc_int_div_8_loop
		ld	b,a
		ld	a,e
		rla
		cpl
		pop	de
		pop	af
		ret

; Name: calc_int_div_16
; Desc:	Divide two 16-bit integers with 16-bit result
; In:	BC = dividend, DE = divisor
; Out:	BC = quotient, HL = remainder
calc_int_div_16:
		push	af
		ld	hl,0
		ld	a,b
		ld	b,16
calc_int_div_16_loop:	
		rl	c
		rla
		adc	hl,hl
		sbc	hl,de
		jr	nc,calc_int_div_16_no_add
		add	hl,de
calc_int_div_16_no_add:
		djnz	calc_int_div_16_loop
		rl	c
		rla
		cpl
		ld	b,a
		ld	a,c
		cpl
		ld	c,a
		pop	af
		ret

; Name:	calc_int_mult_8
; Desc: Multiply two 8-bit integers with 16-bit result
; In:	H,E = values to multiply
; Out:	HL = result
calc_int_mult_8:
		push	bc
		push	de
		ld	d,0
		ld	l,d
		ld	b,8
calc_int_mult_8_loop:
		add	hl,hl
		jr	nc,calc_int_mult_8_no_add
		add	hl,de
calc_int_mult_8_no_add:
		djnz	calc_int_mult_8_loop
		pop	de
		pop	bc
		ret

; Name: calc_int_mult_16
; Desc:	Multiply two 16-bit integers with 32-bit result
; In:	BC,DE = values to multiply
; Out:	BCHL = result
calc_int_mult_16:
		push	af
		ld	a,c
		ld	c,b
		ld	hl,0
		ld	b,16
calc_int_mult_16_loop:
		add	hl,hl
		rla
		rl	c
		jr	nc,calc_int_mult_16_no_add
		add	hl,de
		adc	a,0
		jp	nc,calc_int_mult_16_no_add
		inc 	c
calc_int_mult_16_no_add:
		djnz	calc_int_mult_16_loop
		ld	b,c
		ld	c,a
		pop	af
		ret

