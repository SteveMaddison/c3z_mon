;
; User Datagram Protocol (RFC 768)
;
; Steve Maddison, 15/01/2008
;

udp_hdr_src_port:		equ	0
udp_hdr_dest_port:		equ	2
udp_hdr_length:			equ	4
udp_hdr_checksum:		equ	6
udp_hdr_data:			equ	7

; Name: udp_rx
; Desc: Process a received UDP datagram
; In:	HL = Address of data buffer
;	DE = Data length
;	IX = Address op IP header
udp_rx:
	ret
