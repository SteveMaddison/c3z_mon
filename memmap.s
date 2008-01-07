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

env_data_start:		equ	cli_buffer_end + 1
env_data_size:		equ	512
env_data_end:		equ	env_data_start + env_data_size -1
env_start_ptr:		equ	env_data_end + 1
env_free:		equ	env_start_ptr + 2

