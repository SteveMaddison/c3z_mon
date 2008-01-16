;
; Linked lists
;
; Steve Maddison, 20/03/2007
;


; Name: ll_add
; Desc: Add an existing item to a linked list
; In:	HL = start pointer
;	DE = address of item
ll_add:		push	af
		call	ll_get_end
		ld	(hl),e
		inc	hl
		ld	(hl),d
		xor	a
		ld	(de),a
		inc	de
		ld	(de),a
		pop	af
		ret

; Name: ll_get_end
; Desc:	Point to last item, or start pointer if none.
; In:	HL = start pointer
; Out:	HL = address of last item, or start pointer
ll_get_end:
		push	bc
ll_get_end_loop:
		ld	a,(hl)
		ld	b,a
		inc	hl
		or	(hl)
		jp	z,ll_get_end_end
		ld	h,(hl)
		ld	l,b
		jp	ll_get_end_loop
ll_get_end_end:
		dec	hl
		pop	bc
		ret

; Name: ll_search_bin
; Desc: Search linked list for item with given binary value.
; In:	HL = start pointer
;	DE = address of data to search for
;	BC = length of data
; Out:	HL = address of item, or zero if not found,
;	ZF = 1 if found, otherwise 0.
ll_search_bin:
		push	ix	; used to preverve BC
		push	bc
		pop	ix
ll_search_bin_loop:
		push	hl
		inc	hl
		inc	hl
		push	ix
		pop	bc
		call	memcmp
		jp	z,ll_search_bin_found
		pop	hl
		ld	a,(hl)
		ld	b,a
		inc	hl
		or	(hl)
		jp	z,ll_search_bin_not_found
		ld	h,(hl)
		ld	l,b
		jp	ll_search_bin_loop
ll_search_bin_found:
		pop	hl
		jp	ll_search_bin_end
ll_search_bin_not_found:
		dec	a	; We know A = 0
		and	a	; Clear zero flag
ll_search_bin_end:
		pop	ix
		ret

; Name: ll_search_str
; Desc: Search linked list for item with given ID (string).
; In:	HL = start pointer,
;	DE = address of string to search for.
; Out:	HL = address of item, or zero if not found,
;	ZF = 1 if found, otherwise 0.
ll_search_str:	
		push	bc
ll_search_str_loop:
		push	hl
		inc	hl
		inc	hl
		call	strcmp
		jp	z,ll_search_str_found
		pop	hl
		ld	a,(hl)
		ld	b,a
		inc	hl
		or	(hl)
		jp	z,ll_search_str_not_found
		ld	h,(hl)
		ld	l,b
		jp	ll_search_str_loop
ll_search_str_found:
		pop	hl
		jp	ll_search_str_end
ll_search_str_not_found:
		dec	a	; We know A = 0
		and	a	; Clear zero flag
ll_search_str_end:
		pop	bc
		ret

