;
; Network Sockets
;
; Steve Maddison, 15/01/2008
;

sock_struct_next:		equ	0
sock_struct_his_addr:		equ	2	;\
sock_struct_my_addr:		equ	6	; \
sock_struct_his_port:		equ	10	;  } Key for linked list.
sock_struct_my_port:		equ	12	; /
sock_struct_protocol:		equ	14      ;/
sock_struct_callback:		equ	15
sock_struct_length:		equ	17

sock_struct_key_length:		equ	13


sock_init:
	ld	hl,0
	ld	(sock_start),hl
	ret

; Name: sock_search
; Desc: Find a socket matching given criteria
; In:   IX = address of IP header (for src/dest addresses)
;	BC = my port
;	DE = his port
;	A = protocol
; Out:	HL = address of socket structure, or zero if not found,
;	ZF = 1 if found, otherwise 0.
sock_search:
	push	bc	; save
	push	de
	push	hl
	ld	de,sock_scratch
	push	ix
	pop	hl
	ld	bc,ip_hdr_src_addr
	add	hl,bc
	ld	bc,ip_addr_length*2
	ldir
	pop	hl	; restore
	pop	de
	pop	bc
	ld	ix,sock_scratch
	ld	(ix+sock_struct_my_port+0),b
	ld	(ix+sock_struct_my_port+1),c
	ld	(ix+sock_struct_his_port+0),d
	ld	(ix+sock_struct_his_port+1),e
	ld	(ix+sock_struct_protocol),a
	ld	hl,(sock_start)
	ld	bc,sock_struct_key_length
	ld	de,sock_scratch
	call	ll_search_bin
	ret
