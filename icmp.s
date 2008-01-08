;
; Internet Control Message Protocol (RFC 792)
;
; Steve Maddison, 08/01/2008
;

; ICMP header offsets
icmp_hdr_type:			equ	0
icmp_hdr_code:			equ	1
icmp_hdr_checksum:		equ	2
; Bytes 4 thru 7 have different uses
icmp_hdr_ident:			equ	4
icmp_hdr_pointer:		equ	4
icmp_hdr_gateway:		equ	4
icmp_hdr_seq_number:		equ	6
; Byte 8 onwards is used for "data", often the first few
; bytes of the original packet, but sometimes other stuff.
icmp_hdr_data:			equ	8
icmp_hdr_orig_timestamp:	equ	8
icmp_hdr_rec_timestamp:		equ	12
icmp_hdr_tx_timestamp:		equ	16

; ICMP Types/codes
;  Destination Unreachable
icmp_type_dest_unreachable:	equ	3
	icmp_code_net_unreachable:	equ	0
	icmp_code_host_unreachable:	equ	1
	icmp_code_proto_unreachable:	equ	2
	icmp_code_port_unreachable:	equ	3
	icmp_code_fragment_needed:	equ	4
	icmp_code_source_failed:	equ	5
;  Source Quench
icmp_type_source_quench:	equ	4
;  Redirect
icmp_type_redirect:		equ	5
	icmp_code_redir_network:	equ	0
	icmp_code_redir_host:		equ	1
	icmp_code_redir_tos_network:	equ	2
	icmp_code_redir_tos_host:	equ	3
;  Echo
icmp_type_echo_request:		equ	8
icmp_type_echo_reply:		equ	0
;  Time Exceeded
icmp_type_time_exceeded:	equ	11
	icmp_code_ttl_exceeded:		equ	0
	icmp_code_frag_time_exceeded:	equ	1
;  Parameter Problem
icmp_type_param_problem:	equ	12
;  Timestamps
icmp_type_timestamp_request:	equ	13
icmp_type_timestamp_reply:	equ	14
;  Information
icmp_type_info_request:		equ	15
icmp_type_info_reply:		equ	16

; Data to send with echo messages
icmp_echo_data:			defm	"ABCDEFGH"
icmp_echo_data_length:		equ	8

; Name: icmp_rx
; Desc: Process ICMP message
; In:	HL = Address of data buffer
;	DE = Data length
;	IX = Address of IP header
icmp_rx:
	ld	a,(hl)		; get message type
icmp_rx_echo_request:
	cp	icmp_type_echo_request
	jp	nz,icmp_rx_echo_response
	jp	icmp_rx_end
icmp_rx_echo_response:
	cp	icmp_type_echo_response
	jp	nz,icmp_rx_end
icmp_rx_end:
	ret

; Name: icmp_tx_echo
; Desc: Send an ICMP echo or echo reply message (types 0 or 8)
; In:	A = mesage type
;	BCDE = destination IP address
icmp_tx_echo:
	ld	ix,icmp_scratch
	ld	(ix+icmp_hdr_type),a
	ld	(ix+icmp_hdr_code),0
	ld	(ix+icmp_hdr_checksum+0),0
	ld	(ix+icmp_hdr_checksum+1),0
	push	bc
	push	de
	ld	de,icmp_scratch+icmp_hdr_data
	ld	hl,icmp_echo_data
	ld	bc,icmp_echo_data_length
	ldir
	pop	de
	pop	bc
	ld	hl,icmp_hdr_data+icmp_echo_data_length
	call	ip_calc_checksum
	push	hl
	pop	iy
	ld	hl,icmp_scratch
	ld	a,ip_proto_icmp
	call	ip_tx
	ret
