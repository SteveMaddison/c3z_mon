;
; User Datagram Protocol (RFC 768)
;
; Steve Maddison, 15/01/2008
;

udp_hdr_src_port:		equ	0
udp_hdr_dest_port:		equ	2
udp_hdr_length:			equ	4
udp_hdr_checksum:		equ	6
udp_hdr_data:			equ	8

; Name: udp_rx
; Desc: Process a received UDP datagram
; In:	HL = Address of data buffer
;	DE = Data length
;	IX = Address op IP header
udp_rx:		; xxx - checksum
		push 	de	; save
		push	hl
		push	hl	; swap
		pop	iy
		ld	b,(iy+udp_hdr_dest_port+0)
		ld	c,(iy+udp_hdr_dest_port+1)
		ld	d,(iy+udp_hdr_src_port+0)
		ld	e,(iy+udp_hdr_src_port+1)
		ld	a,ip_proto_udp
		call	sock_search
		push	hl	; swap
		pop	ix
		pop	hl	; restore
		pop	de
		jp	nz,udp_rx_discard
		call	sock_callback
udp_rx_discard:
		ret
