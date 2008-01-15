;
; Pseudo-header used by UDP and TCP
;
; Steve Maddison, 15/01/2008
;

pseudo_hdr_src_addr:		equ	0
pseudo_hdr_dest_addr:		equ	4
pseudo_hdr_zero:		equ	8
pseudo_hdr_protocol:		equ	9
pseudo_hdr_length:		equ	10

; Name: pseudo_checksum
; Desc: Create pseudo header checksum using IP header
; In:	IX = address of IP header
;	DE = value for length field
;	HL = checksum start value
; Out:	HL = calculated checksum
pseudo_checksum:
	push	bc
	push	ix
	call	pseudo_load
	ld	ix,pseudo_scratch
	ld	bc,pseudo_scratch_length
	call	ip_calc_checksum
	pop	ix
	pop	bc
	ret

; Name: pseudo_load
; Desc: Create pseudo header using IP header
; In:	IX = address of IP header
;	DE = value for length field
pseudo_load:
	push	af
	push	hl
	push	de
	; Copy source/destination addresses
	push	ix
	pop	hl
	ld	bc,ip_hdr_src_addr
	add	hl,bc
	ld	de,pseudo_scratch+pseudo_hdr_src_addr
	ld	bc,ip_addr_length*2
	ldir
	; Save protocol and IX so we can
	ld	a,(ix+ip_hdr_protocol)
	; Restore the length field value
	pop	de
	push	ix
	ld	ix,pseudo_scratch
	ld	(ix+pseudo_hdr_zero),0
	ld	(ix+pseudo_hdr_protocol),a
	ld	(ix+pseudo_hdr_length+0),d
	ld	(ix+pseudo_hdr_length+1),e
	pop	ix
	pop	hl
	pop	af
	ret
