;
; Internet Control Message Protocol (RFC 792)
;
; Steve Maddison, 08/01/2008
;

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


; Name: icmp_rx
; Desc: Process ICMP message
; In:	HL = Address of data buffer
;	DE = Data length
;	IX = Address op IP header
icmp_rx:
	ret

; Name: icmp_tx
; Desc: Send an ICMP message
; In:	A = mesage type
;	BCDE = destination IP address
;	HL = address of data buffer
;	IY = data buffer length
icmp_tx:
icmp_tx_echo_reply:
	cp	icmp_type_echo_reply
	jp	nz,icmp_tx_echo_request
	
	jp	icmp_tx_end
icmp_tx_echo_request:
	cp	icmp_type_echo_request
	jp	nz,icmp_tx_end
	
icmp_tx_end:
	ret	
