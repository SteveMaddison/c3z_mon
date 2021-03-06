;
; Memory map for monitor-related data
;
; Steve Maddison, 14/02/2007
;

rom_start:		equ	0x0000
rom_end:		equ	0x3fff
ram_start:		equ	0x4000
ram_end:		equ	0xffff
stack_top:		equ	ram_end - 1

cli_buffer:		equ	ram_start
cli_buffer_size:	equ	128
cli_buffer_end:		equ	cli_buffer + cli_buffer_size - 1
cli_retval:		equ	cli_buffer_end + 1

dev_start_ptr:		equ	cli_retval + 1

ide_internal_buffer:	equ	dev_start_ptr + 2
ide_config:		equ	ide_internal_buffer + 512

fs_buffer_ptr:		equ	ide_config + 1

slip_internal_buffer:	equ	fs_buffer_ptr + 2
; Historical (BSD) maximum datagram size, including headers, but
; excluding special framing characters.
slip_buffer_size:	equ	1006
slip_buffer_end:	equ	slip_internal_buffer + slip_buffer_size - 1
slip_buffer_ptr:	equ	slip_buffer_end + 1

ip_addr:		equ	slip_buffer_ptr + 1
ip_addr_length:		equ	4
ip_addr_end:		equ	ip_addr + ip_addr_length - 1
ip_broadcast:		equ	ip_addr_end + 1
ip_broadcast_end:	equ	ip_broadcast + ip_addr_length - 1
ip_hdr_scratch:		equ	ip_broadcast_end + 1
ip_hdr_scratch_length:	equ	ip_ihl_max << 4
ip_hdr_scratch_end:	equ	ip_hdr_scratch + ip_hdr_scratch_length - 1

icmp_scratch:		equ	ip_hdr_scratch_end + 1
; ICMP message is 8 bytes, plus original IP header, plus 64-bits of data.
; Echo messages are allowed to be longer but we just won't send longer.
icmp_scratch_length:	equ	ip_hdr_scratch_length + 16
icmp_scratch_end:	equ	icmp_scratch + icmp_scratch_length - 1

pseudo_scratch:		equ	icmp_scratch_end + 1
pseudo_scratch_length:	equ	12
pseudo_scratch_end:	equ	pseudo_scratch + pseudo_scratch_length + 1

udp_scratch:		equ	pseudo_scratch_end + 1
udp_scratch_length:	equ	8
udp_scratch_end:	equ	udp_scratch + udp_scratch_length - 1

sock_start:		equ	udp_scratch_end + 1
sock_scratch:		equ	sock_start + 2
sock_scratch_end:	equ	sock_scratch + sock_struct_key_length - 1

;env_data_start:		equ	cli_buffer_end + 1
;env_data_size:		equ	512
;env_data_end:		equ	env_data_start + env_data_size -1
;env_start_ptr:		equ	env_data_end + 1
;env_free:		equ	env_start_ptr + 2

; This must come last!
mem_heap_ptr:		equ	sock_scratch_end + 1
mem_heap:		equ	mem_heap_ptr + 2
