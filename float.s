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
; Exponent is as excess-127, 0 and 255 have special meaning.
float_excess:		equ	127
float_max_exponent:	equ	254
float_min_exponent:	equ	1

; Name:	float_add
; Desc:	Add two floating point numbers
; In:	BCDE, BC'DE' = numbers to add
; Out:	BCDE = result
;	A = 0 on success, otherwise error code
float_add:
		push	hl
		; Find which number has the smallest exponent, and make sure
		; it's in the main register set (BCDE) in order to simplify
		; the exponent matching phase. The largest exponent is stored
		; in A for the same reason.
		ld	a,b	; Fetch B
		exx
		cp	b	; Compare with B' 
		jp	z,float_add_match_exp_end
		jp	c,float_add_match_exp_loop
		ld	a,b	; Overwrite A - this B is larger
		exx
		; Match exponents of both numbers by altering the value
		; with the smallest exponent.
float_add_match_exp_loop:
		inc	b	; increment exponent
		sra	c	; shift mantissa, maintining sign bit
		rr	d
		rr	e
		cp	b	; compare exponents
		jp      nz,float_add_match_exp_loop
float_add_match_exp_end:
		; Add the 2's complement representation of the mantissas
		; using AHL as the target.
		call	float_sm_2s_comp
		push	de	; save DE
		ld	a,c	; save C -> A
		exx		; get the second parameter
		call	float_sm_2s_comp
		pop	hl	; restore DE, but into HL
		add	hl,de	; add DE' to DE
		adc	a,c	; add C' to C (with carry)
		push	af	; store carry flag (see below)
		; Transfer the resulting mantissa in AHL to CDE
		ld	c,a	; A -> C
		push	hl	; HL -> DE
		pop	de
		; Convert back to sign and magnitude (only required if
		; result is negative).
		bit	7,c	; set if value is negative
		jp	z,float_add_check_carry
		call	float_2s_comp
		set	7,c	; set sign bit
float_add_check_carry:
		; If mantissa addition resulted in carry, shift the
		; carry bit into the result and increment the exponent
		pop	af	; restore carry flag
		jp	nc,float_add_normalise
		inc	b	; increment exponent
		ld	a,float_max_exponent
		cp	b
		jp	nc,float_add_no_overflow
		ld	a,error_overflow
		jp	float_add_end
float_add_no_overflow:
		; Transfer carry to what would usually be the sign bit, so
		; it gets rotated into the mantissa.
		ld	a,c
		or	%10000000
		ld	c,a
		rr	c	; shift mantissa right
		rr	d
		rr	e
		ld	a,0	; signal success
		; We already know the mantissa has no leading zeros, so
		; normalisation can be skipped.
		jp	float_add_end
float_add_normalise:
		; Normalise the result before returning
		call	float_normalise
float_add_end:
		pop	hl
		ret

; Name:	float_normalise
; Desc:	Normalise floating point value
; In:	BCDE = number to normalise
; Out:	BCDE = normalised number
;	A = 0 on success, otherwise error code
float_normalise:
		; Keep sign bit in B so we can restore it afterwards.
		; Using A for exponent makes calculations simpler.
		ld	a,b
		push	af
		ld	a,c
		and	%10000000
		ld	b,a
		pop	af
float_normalise_loop:
		bit	6,c
		jp	nz,float_normalise_restore_sign
		dec	a
		cp	float_min_exponent-1
		jp	nz,float_normalise_no_underflow
		ld	a,error_underflow
		jp	float_normalise_end
float_normalise_no_underflow:
		rl	e
		rl	d
		rl	c
		jp	float_normalise_loop
float_normalise_restore_sign:
		or	b
		ld	b,a
		ld	a,0	; signal success
float_normalise_end:
		ret

; Convert 1+23-bit sign and magnitude in CDE to 24-bit 2's complement
float_sm_2s_comp:
		bit	7,c
		ret	z		; no conversion necessary
		res	7,c		; clear sign bit and fall through
; Calculate 2's complement of CDE
float_2s_comp:
		push	af
		push	hl
		; Invert C, D and E
		ld	a,c
		cpl
		ld	c,a
		ld	a,d
		cpl
		ld	d,a
		ld	a,e
		cpl
		ld	e,a
		; Increment CDE (need to use add instead of inc as
		; we need carry flag)
		ld	hl,1
		add	hl,de
		jp	nc,float_2s_comp_end
		inc	c
float_2s_comp_end:
		push	hl	; HL -> DE
		pop	de
		pop	hl
		pop	af
		ret

; Subtract BC'DE' from BCDE
float_sub:
		; Negate the second parameter
		exx
		ld	a,c
		xor	%10000000	; invert sign bit
		ld	c,a
		exx
		; When registers are swapped back, call the addition routine
		call	float_add
		ret

