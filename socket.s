;
; Network Sockets
;
; Steve Maddison, 15/01/2008
;

sock_struct_next:		equ	0
sock_struct_src_addr:		equ	2
sock_struct_dest_addr:		equ	6
sock_struct_src_port:		equ	10
sock_struct_dest_port:		equ	12
sock_struct_callback:		equ	14
sock_struct_protocol:		equ	16
sock_struct_length:		equ	17

sock_init:
	ld	hl,sock_start
	ld	(hl),0
	inc	hl
	ld	(hl),0
	ret
