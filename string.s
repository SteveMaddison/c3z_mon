;
; String functions
;
; Steve Maddison, 27/02/2007
;
; Although the Z80's block instructions would be useful here, they cannot
; be used effectively either due to:
;  1) having to check for the terminating '\0', or
;  2) we want BC to count upwards and not down.

; Name:	strcmp
; Desc:	Compare strings
; In:	HL, DE = addresses of strings to compare
; Out:	Zero flag set if strings match
strcmp:
	push	bc
	ld	bc,0xffff	; max out counter
	call	strncmp
	pop	bc
	ret

; Name:	strncmp
; Desc:	Compare first n characters of strings
; In:	HL, DE = addresses of strings to compare
;	BC = number of characters to check (n)
; Out:	Zero flag set if strings match
strncmp:
	ld	a,b			; check if counter is 0
	or	c
	jp	z,strncmp_end
	ld	a,(de)			; compare bytes
	cp	(hl)
	jp	nz,strncmp_end
	cp	0			; end of first string?
	jp	z,strncmp_check
	inc	de
	inc	hl
	dec	bc
	jp	strncmp
strncmp_check:				; check end of second string
	or	(hl)			; has been reached too
	cp	0
strncmp_end:
	ret

; Name:	strncpy
; Desc:	Copy a string
; In:	HL = address of source string
;	DE = address of destination buffer
; Out:	none
strcpy:
	push	bc
	ld	bc,0xffff	; max out counter
	call	strncpy
	pop	bc
	ret

; Name:	strncpy
; Desc:	Copy first n characters of a string
; In:	HL = address of source string
;	DE = address of destination buffer
;	BC = number of characters to copy (n)
; Out:	none
strncpy:
	ld	a,b
	or	c
	jp	z,strncpy_end
	ld	a,(hl)
	ld	(de),a
	inc	hl
	inc	de
	dec	bc
	cp	0
	jp	nz,strncpy
strncpy_end:
	ret

; Name:	strlen
; Desc:	Find length of string (excluding terminating \0)
; In:	HL = address of string
; Out:	BC = length of string
strlen:
	ld	bc,0
strlen_loop:
	ld	a,(hl)
	cp	0
	jp	z,strlen_end
	inc	hl
	inc	bc
	jp	strlen_loop
strlen_end:
	ret

