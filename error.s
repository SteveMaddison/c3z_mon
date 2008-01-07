;
; Error codes and messages
;
; Steve Maddison, 25/02/2007
;

error_div_0:		equ	0x01
error_overflow:		equ	0x02
error_underflow:	equ	0x03
error_max:		equ	0x04

error_str_div0:		defm	"Division by 0\0"
error_str_overflow:	defm	"Overflow\0"
error_str_underflow:	defm	"Underflow\0"

error_str_unknown:	defm	"Unknown error\0"

error_str_table:	defw	error_str_unknown
			defw	error_str_div0
			defw	error_str_overflow
			defw	error_str_underflow

; Name: error_str
; Desc:	Return natural language error message
; In:	A = error code
; Out:	HL = address of error message string
error_str:	
		push	bc
		; Check A is a valid error code
		cp	error_max
		jp	nc,error_str_valid
		xor	a	; 0 = unknown error
error_str_valid:
		; Load HL with address of table + (2 * A)
		ld	hl,error_str_table
		ld	b,0
		ld	c,a
		add	hl,bc	; Yes, slower than multiplying A,
		add	hl,bc	; but it's 16-bit safe
		; Load HL with word (HL)
		ld	c,(hl)
		inc	hl
		ld	b,(hl)
		push	bc
		pop	hl
		pop	bc
		ret

