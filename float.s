;
; Floating point numbers
;
; Steve Maddison, 25/02/2007
;

; All floating point numbers are 32-bit. The 8-bit exponent is
; placed at the start for easy access. The sign bit is the the
; most significant bit of the next byte, also easily tested for
; or removed to access the mantissa (remaining 23 bits).
float_exponent:		equ	0	; 8-bit exponent
float_sign:		equ	8	; sign bit (set = negative)
float_mantissa:		equ	9	; 23-bit mantissa

; Add BC'DE' to BCDE
float_add:
		push	af
		push	hl
		; find which exponent is smaller
		exx
		ld	a,b
		exx
		cp	b
		jp	z,float_add_match_exp_end
		jp	nc,float_add_match_exp_loop
		ld	a,b	; keep track of exponent in A
		exx		; get number with smallest
				; exponent into main registers
float_add_match_exp_loop:
		inc	b	; increment exponent
		sra	c	; shift mantissa, maintining sign bit
		rr	d
		rr	e
		cp	b	; compare exponents
		jp      nz,float_add_match_exp_loop
float_add_match_exp_end:
		bit	7,c
		jp	z,float_add_1st_positive
		call	float_sm_2s_comp
float_add_1st_positive:
		push	de	; save DE
		ld	a,c	; C -> A
		exx
		bit	7,c
		jp	z,float_add_2nd_positive
		call	float_sm_2s_comp
float_add_2nd_positive:
		pop	hl	; restore DE
		add	hl,de	; add DE' to DE
		adc	a,c	; add C' to C (with carry)
float_add_result:
		ld	c,a	; A -> C
		push	hl	; HL -> DE
		pop	de
		bit	7,c
		jp	z,float_add_result_positive
		call	float_2s_comp
		set	7,c
float_add_result_positive:
		pop	hl
		pop	af
		ret

; Convert 1+23-bit sign and magnitude in CDE to 24-bit 2's complement
float_sm_2s_comp:
		push	af
		ld	a,c
		and	0x7f
		ld	c,a
		call	float_2s_comp
		pop	af
		ret

float_2s_comp:
		push	af
		push	hl
		ld	a,c
		cpl
		ld	c,a
		ld	a,d
		cpl
		ld	d,a
		ld	a,e
		cpl
		ld	e,a
		push	de
		pop	hl
		push	bc
		ld	bc,1
		add	hl,bc
		pop	bc
		jp	nc,float_2s_comp_end
		inc	c
float_2s_comp_end:
		push	hl
		pop	de
		pop	hl
		pop	af
		ret

; Subtract BC'DE' from BCDE
float_sub:
		exx
		ld	a,c
		xor	%10000000	; invert sign bit
		ld	c,a
		exx
		call	float_add
		ret

