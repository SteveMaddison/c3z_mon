;
; Integer mathematical subroutines
;
; Steve Maddison, 12/02/2007
; Multiplication/division routines based on those
; at http://map.tni.nl/articles/mult_div_shifts.php
;

; Name: int_2s_comp_16
; Desc: Calculate 2's complement of 16-bit value
; In:	HL = value to complement
; Out:	HL = complemented value
int_2s_comp_16:
		push	af
		ld	a,h
		cpl
		ld	h,a
		ld	a,l
		cpl
		ld	l,a
		inc	hl
		pop	af
		ret

; Name: int_div_8
; Desc:	Divide two 8-bit integers with 8-bit result
; In:	E = dividend, C = divisor
; Out:	A = quotient (E/C), B = remainder
int_div_8:
		ld	a,c
		cp	0
		jp	nz,int_div_8_non_zero
		ld	a,error_div_0
		call	crash
int_div_8_non_zero:
		push	de	; save D
		xor	a
		ld	b,8
int_div_8_loop:
		rl	e
		rla
		sub	c
		jr	nc,int_div_8_no_add
		add	a,c
int_div_8_no_add:
		djnz	int_div_8_loop
		ld	b,a
		ld	a,e
		rla
		cpl
		pop	de
		ret

; Name: int_div_16
; Desc:	Divide two 16-bit integers with 16-bit result
; In:	BC = dividend, DE = divisor
; Out:	BC = quotient (BC/DE), HL = remainder
int_div_16:
		push	af
		ld	a,d
		or	e
		jp	nz,int_div_16_non_zero
		ld	a,error_div_0
		call	crash
int_div_16_non_zero:
		ld	hl,0
		ld	a,b
		ld	b,16
int_div_16_loop:	
		rl	c
		rla
		adc	hl,hl
		sbc	hl,de
		jr	nc,int_div_16_no_add
		add	hl,de
int_div_16_no_add:
		djnz	int_div_16_loop
		rl	c
		rla
		cpl
		ld	b,a
		ld	a,c
		cpl
		ld	c,a
		pop	af
		ret

; Name:	int_mult_8
; Desc: Multiply two 8-bit integers with 16-bit result
; In:	H,E = values to multiply
; Out:	HL = result
int_mult_8:
		push	bc
		push	de
		ld	d,0
		ld	l,d
		ld	b,8
int_mult_8_loop:
		add	hl,hl
		jr	nc,int_mult_8_no_add
		add	hl,de
int_mult_8_no_add:
		djnz	int_mult_8_loop
		pop	de
		pop	bc
		ret

; Name: int_mult_16
; Desc:	Multiply two 16-bit integers with 32-bit result
; In:	BC,DE = values to multiply
; Out:	BCHL = result
int_mult_16:
		push	af
		ld	a,c
		ld	c,b
		ld	hl,0
		ld	b,16
int_mult_16_loop:
		add	hl,hl
		rla
		rl	c
		jr	nc,int_mult_16_no_add
		add	hl,de
		adc	a,0
		jp	nc,int_mult_16_no_add
		inc 	c
int_mult_16_no_add:
		djnz	int_mult_16_loop
		ld	b,c
		ld	c,a
		pop	af
		ret

