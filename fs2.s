;
; File System Stuff
;
; Steve Maddison, 19/02/2007
;

fs_magic:		defm	"CSFS\0"
fs_version:		defm	"0001\0"

fs_block_shift_min:	equ	8
fs_block_size_min:	equ	1 << fs_block_size_min
fs_block_dividend:	equ	0x0200	; 128K >> 8

fs_super_magic:		equ	0
fs_super_version:	equ	4
fs_super_block_size:	equ	8
fs_super_capacity:	equ	12
fs_super_free:		equ	16
fs_super_root_ptr:	equ	20
fs_super_reserved:	equ	24	; For expansion
fs_super_label:		equ	40

fs_header_magic:	equ	0
fs_header_flags:	equ	1
fs_header_next_ptr:	equ	4
fs_header_prev_ptr:	equ	8
fs_header_len:		equ	12

fs_name_offset:		equ	12
fs_name_len:		equ	40
fs_size_offset:		equ	52
fs_size_len:		equ	4
fs_data_offset:		equ	64

fs_flag_dir:		equ	0x80
fs_flag_read:		equ	0x04
fs_flag_write:		equ	0x02
fs_flag_exec:		equ	0x01

fs_info_create:		defm	"Creating FS on \0"
fs_info_block_size:	defm	"Block size: \0"
fs_info_capacity:	defm	"Capacity: \0"
fs_info_atb:		defm	"ATB: \0"
fs_info_debug:		defm	"\ndebug\n\0"


fs_debug:
		push	hl
		ld	hl,fs_info_debug
		call	console_outs
		pop	hl
		ret

; Name: fs_create
; Desc: Create a filesystem on a block device
; In:	DE = device name
fs_create:	
		call	dev_search
		jp	nz,fs_create_not_found
		push	hl			; Save device record address...
		pop	ix			; ...in IX

		ld	hl,fs_info_create
		call	console_outs
		ld	hl,(ix+dev_struct_name)
		call	console_outs
		ld	a,'\n'
		call	console_outb

		call	dev_get_buffer		; Get a buffer address.
		ld	(fs_buffer_ptr),hl
		ld	b,(ix+dev_struct_block_size)
		ld	c,0
fs_create_clear_buffer_loop:
		ld	(hl),0
		inc	hl
		dec	bc
		ld	a,b
		or	c
		jp	nz,fs_create_clear_buffer_loop
		; Write magic		
		ld	de,(fs_buffer_ptr)
		ld	hl,fs_magic
		call	strcpy
		; Divide block dividend by block size (both values
		; being >> 8)
		ld	a,(ix+dev_struct_block_size)
		ld	hl,fs_block_dividend
fs_create_calc_blocking_factor:
		cp	1
		jp	z,fs_create_calc_blocks
		srl	a
		srl	h
		rr	l
		jp	fs_create_calc_blocking_factor
fs_create_calc_blocks:
		push	hl	; Remember blocking factor
		call	dev_get_size
		; BCDE contains the device's capacity.
		; This needs to be divided by the blocking factor.
		pop	hl	; Restore blocking factor
fs_create_calc_blocks_loop:
		ld	a,l
		cp	1
		jp	z,fs_create_round_block_size
		srl	h	; shift HL
		rr	l
		srl	b	; shift BCD
		rr	c
		rr	d
		rr	e
		jp	fs_create_calc_blocks_loop
fs_create_round_block_size:
		; BCDE now contains the calculated block size.
		; Round it up to the nearest power of 2.
		ld	l,0
fs_create_round_right_loop:
		inc	l
		srl	b
		rr	c
		rr	d
		rr	e
		ld	a,b
		or	c
		or	d
		or	e
		jp	nz,fs_create_round_right_loop
		; Initialise BCDE = 1
		ld	bc,0
		ld	de,1
		; Ensuring the value meets the required minimum.
		ld	a,l
		cp	fs_block_shift_min
		jp	nc,fs_create_round_left_loop
		ld	l,fs_block_shift_min
		; Shift the 1 left "L" places.
fs_create_round_left_loop:
		rl	e
		rl	d
		rl	c
		rl	b
		dec	l
		ld	a,l
		cp	0
		jp	nz,fs_create_round_left_loop
		; BCDE now contains actual block size for this FS 
		ld	hl,fs_info_block_size
		call	console_outs
		call	print_hex_32
		ld	a,'\n'
		call	console_outb
		; Write block size to the superblock
		ld	hl,fs_buffer_ptr
		push	bc
		ld	bc,fs_super_block_size
		and	a
		adc	hl,bc
		pop	bc
		ld	(hl),b
		inc	hl
		ld	(hl),c
		inc	hl
		ld	(hl),d
		inc	hl
		ld	(hl),e
		; Divide the block size by the device's block size.
		ld	h,(ix+dev_struct_block_size)
		ld	l,0
fs_create_divide_block_loop:
		ld	a,l
		cp	1
		jp	z,fs_create_calc_capacity
		srl	b
		rr	c
		rr	d
		rr	e
		srl	h
		rr	l
		jp	fs_create_divide_block_loop
fs_create_calc_capacity: 
		exx	; Save result in the alternate registers
		push	ix
		pop	hl
		call	dev_get_size
		exx
fs_create_calc_capacity_loop:
		ld	a,e
		cp	1
		jp	z,fs_create_write_capacity
		exx
		srl	b
		rr	c
		rr	d
		rr	e
		exx
		srl	b
		rr	c
		rr	d
		rr	e
		jp	fs_create_calc_capacity_loop
fs_create_write_capacity:
		exx
		; BCDE now contains device's capacity in blocks of
		; the calculated size.
		ld	hl,fs_info_capacity
		call	console_outs
		call	print_hex_32
		ld	a,'\n'
		call	console_outb
		; Write to buffer
		ld	hl,fs_buffer_ptr
		push	bc
		ld	bc,fs_super_capacity
		and	a
		adc	hl,bc
		pop	bc
		ld	(hl),b
		inc	hl
		ld	(hl),c
		inc	hl
		ld	(hl),d
		inc	hl
		ld	(hl),e
		; We need BCDE bits int the ATB, so divide by 8 to calcualte
		; the bytes required for the Allocation Table Bitmap.
		ld	a,3	; shift >> 3
fs_create_calc_atb_bytes_loop:
		srl	b
		rr	c
		rr	d
		rr	e
		dec	a
		and	a
		jp	nz,fs_create_calc_atb_bytes_loop
		; BCDE now contains the number of bytes required. What
		; we need is the number of blocks, so divide by block size.
		exx
		ld	hl,fs_buffer_ptr
		ld	bc,fs_super_block_size
		and	a
		adc	hl,bc
		ld	b,(hl)
		inc	hl
		ld	c,(hl)
		inc	hl
		ld	d,(hl)
		inc	hl
		ld	e,(hl)
fs_create_calc_atb_blocks_loop:
		ld	a,e
		cp	1
		jp	z,fs_create_calc_root_ptr
		exx
		srl	b
		rr	c
		rr	d
		rr	e
		exx
		srl	b
		rr	c
		rr	d
		rr	e
		jp	fs_create_calc_atb_blocks_loop
fs_create_calc_root_ptr:
		exx
		; BCDE now contains the number of blocks required for the ATB.
		; Check BCDE is not zero, indicating the ATB fits in less than
		; one block, and increment if necessary.
		ld	a,b
		or	c
		jp	nz,fs_create_print_atb
		ld	a,d
		or	e
		jp	nz,fs_create_print_atb
		inc	de	
fs_create_print_atb:
		ld	hl,fs_info_atb
		call	console_outs
		call	print_hex_32
		ld	a,'\n'
		call	console_outb
		; As block 0 is the super block, and this is directly followed
		; by the ATB, adding one to BCDE will give us the location of
		; the first available block, which is where the root directory
		; is to be created.
		inc	de
		ld	a,d
		or	e
		jp	nz,fs_create_write_root_ptr
		inc	bc
fs_create_write_root_ptr:
		ld	hl,fs_buffer_ptr
		push	bc
		ld	bc,fs_super_root_ptr
		and	a
		adc	hl,bc
		pop	bc
		ld	(hl),b
		inc	hl
		ld	(hl),c
		inc	hl
		ld	(hl),d
		inc	hl
		ld	(hl),e
		; Write the superblock to disk now - we need the buffer for
		; zeroing the ATB.
		exx
		ld	bc,0
		ld	de,0
		ld	hl,(fs_buffer_ptr)
		call	dev_write
		exx
		; Now increment BCDE again. This makes writing the ATB blocks
		; simple as blocks 1 thru BCDE will be those we need to zero out.
		ld	a,d
		or	e
		jp	nz,fs_create_write_atb
		dec	bc
fs_create_write_atb:
		dec	de

		; Store number of sectors per block in B'C'D'E' (required for the
		; calls to fs_zero_block).
		exx
		ld	hl,fs_buffer_ptr
		ld	bc,fs_super_block_size
		and	a
		adc	hl,bc
		ld	b,0
		ld	c,(hl)
		inc	hl
		ld	d,(hl)
		inc	hl
		ld	e,(hl)
		ld	a,(ix+dev_struct_block_size)
fs_create_calc_sectors_loop:
		cp	a,1
		jp	z,fs_create_calc_sectors_done
		srl	a
		srl	c
		rr	d
		rr	e
		jp	fs_create_calc_sectors_loop
fs_create_calc_sectors_done:
		exx
fs_create_atb_loop:
		ld	a,d			; Check DE for zero
		or	e
		jp	nz,fs_create_atb_zero
		ld	a,b			; Check BC for zero too
		or	c
		jp	z,fs_create_atb_done
		dec	bc
fs_create_atb_zero:
		call	fs_zero_block
		dec	de
		jp	fs_create_atb_loop
fs_create_atb_done:

	
		xor	a		; Signal success
		jp	fs_create_end
fs_create_not_found:
		ld	a,error_no_dev
fs_create_end:
		ret

; In:	BCDE = block to zero out
;	B'C'D'E = number of sectors per block
fs_zero_block:
		push	bc	; BCDE and B'C'D'E must remain unchanged!
		push	de
		exx
		push	bc
		push	de
		exx
		call	fs_block_first_sector
		ld	hl,(fs_buffer_ptr)
		push	bc
		ld	b,(ix+dev_struct_block_size)
		ld	c,0
fs_zero_block_clear_buffer:
		ld	(hl),0
		inc	hl
		dec	bc
		ld	a,b
		or	c
		jp	nz,fs_zero_block_clear_buffer
		pop	bc
		ld	hl,(fs_buffer_ptr)
fs_zero_block_loop:
		call	dev_write
		inc	de
		ld	a,d
		or	e
		jp	nz,fs_zero_block_check_end
		inc	bc
fs_zero_block_check_end:
		exx
		ld	a,d
		or	e
		jp	nz,fs_zero_block_next
		ld	a,b
		or	c
		jp	z,fs_zero_block_done
		dec	bc
fs_zero_block_next:
		dec	de
		exx
		jp	fs_zero_block_loop

fs_zero_block_done:
		pop	de
		pop	bc
		exx
		pop	de
		pop	bc
		ret

; In:	BCDE = Block number
;	B'C'D'E = number of sectors per block
; Out:	BCDE = First physical sector of given block
fs_block_first_sector:
fs_block_first_sector_loop:
		exx
		ld	a,e
		cp	1
		jp	z,fs_block_first_sector_done
		srl	b
		rr	c
		rr	d
		rr	e
		exx
		rl	e
		rl	d
		rl	c
		rl	b
		jp	fs_block_first_sector_loop
fs_block_first_sector_done:
		exx
		ret

