;
; Partition table stuff
;
; Steve Maddison, 19/03/2007
;

part_table_magic:		equ	"CSPT\0"
part_table_size:		equ	512
part_table_name_offset:		equ	4
part_table_name_len:		equ	28
part_table_first_partition:	equ	256
part_table_partition_count:	equ	8

part_start:			equ	0
part_end:			equ	4
part_type:			equ	8
part_flags:			equ	9
part_label:			equ	10
part_label_len:			equ	22
part_len:			equ	32

; Write partition table to device
part_write:
		ld	de,ide_internal_buffer
		ld	hl,part_table_magic
		call	strcpy
		; HL now points to terminator of magic string. The
		; remaining bytes are filled with zeros.
		push	hl
		pop	de
		inc	de
		ld	bc,part_table_size-5
		ldir

		; Set sector parameters
		ld	bc,0
		ld	de,0

