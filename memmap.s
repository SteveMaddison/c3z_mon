;
; Memory map for monitor-related data
;
; Steve Maddison, 14/02/2007
;

rom_start:		equ	0x0000
rom_end:		equ	0x3fff
ram_start:		equ	0x4000
ram_end:		equ	0xffff

cli_buffer:		equ	ram_start
cli_buffer_size:	equ	128
cli_buffer_end:		equ	cli_buffer + cli_buffer_size - 1
;cli_buffer_ptr:		equ	ram_start + cli_buffer_size

