;
; Devices
;
; Steve Maddison, 19/03/2007 
;

dev_name_len:		equ	5	; including trailing '\0'

dev_struct_next_ptr:	equ	0
dev_struct_name:	equ	2
dev_struct_id:		equ	dev_struct_name + dev_name_len
dev_struct_flags:	equ	dev_struct_id + 1
dev_struct_block_size:	equ	dev_struct_flags + 1
dev_struct_driver:	equ	dev_struct_block_size + 1
dev_struct_len:		equ	dev_struct_driver + 2

dev_flag_char:		equ	0x01
dev_flag_block:		equ	0x02

dev_driver_read:	equ	0
dev_driver_write:	equ	2
dev_driver_size:	equ	4
dev_driver_buffer:	equ	6


dev_init:
	ld	hl,0
	ld	(dev_start_ptr),hl
	ret

; Name:	dev_add
; Desc:	Add a device to the list
; In:	A  = ID
;	B  = Flags
;	C  = Block Size >> 8 (if applicable)
;	DE = Address of driver structure
;	HL = Device name
dev_add:
	push	bc
	push	hl
	ld	bc,dev_struct_len
	call	mem_heap_alloc
	push	hl
	pop	ix
	pop	hl
	pop	bc

	ld	(ix+dev_struct_id),a		; ID
	ld	(ix+dev_struct_flags),b		; Flags
	ld	a,b				; Block device?
	and	dev_flag_block
	jp	nz,dev_add_block
	ld	c,0
dev_add_block:
	ld	(ix+dev_struct_block_size),c	; Block size >> 8
	ld	(ix+dev_struct_driver),e	; Driver
	ld	(ix+dev_struct_driver+1),d
	push	hl				; Copy name string
	push	ix
	pop	hl
	ld	bc,dev_struct_name
	adc	hl,bc
	push	hl
	pop	de
	pop	hl
	call	strcpy
	push	ix				; Add to linked list
	pop	de
	ld	hl,dev_start_ptr
	call	ll_add
	ret

; Name: dev_jp_driver
; Desc:	Jump to a driver function pointer
; In:	IX = address of function pointer
dev_jp_driver:
	; Jump as opposed to call, to preserve the return address.
	jp	(ix)
	; No "ret" here! We use that of the driver routine we just
	; jumped to.

; Name:	dev_get_buffer
; Desc:	Fetch a valid buffer for a block device
; In:	IX = address of device record.
; Out:	HL = buffer address.
dev_get_buffer:
	ld	iy,dev_driver_buffer
	call	dev_call_driver
	ret

; Name:	dev_get_size
; Desc:	Fetch size of device
; In:	IX = address of device record.
; Out:	BCDE = size of device in blocks.
dev_get_size:
	ld	iy,dev_driver_size
	call	dev_call_driver
	ret

; Name: dev_call_driver
; Desc: Call a device's driver routine
; In:	IX = address of device record
;	HL = address of buffer (where applicable)
; Out:	Depends on driver routine
dev_call_driver:
	push	ix
	push	hl
	push	bc
	ld	a,(ix+dev_struct_id)		; Load device ID
	ld	l,(ix+dev_struct_driver)	; Point to drivers
	ld	h,(ix+dev_struct_driver+1)
	; Get the function pointer at (HL+IY)
	push	iy
	pop	bc
	and	a
	add	hl,bc
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	push	bc
	pop	ix
	pop	bc		; Restore original parameters
	pop	hl
	call	dev_jp_driver
	pop	ix
	ret

; Name:	dev_read
; Desc:	Read form a device
; In:	IX = address of device record.
;	For block devices:
;		BCDE = block number
;		HL = address of buffer
; Out:	Depends on driver routine
dev_read:
	ld	iy,dev_driver_read
	call	dev_call_driver
	ret

; Name: dev_search
; Desc: Search for a device in the linked list
; Name: dev_search
; Desc: Search for a device in the linked list
; In:	DE = Device name
; Out:	HL = Address of device record, or zero if not found
;	ZF = 1 on success, 0 if not found
dev_search:
	ld	hl,dev_start_ptr
	call	ll_search_str
	ret

; Name:	dev_write
; Desc:	Write to a device
; In:	IX = address of device record.
;	For character devices:
;		A = data to write
;	For block devices:
;		BCDE = block number
;		HL = address of buffer
; Out:	Depends on driver routine
dev_write:
	ld	iy,dev_driver_write
	call	dev_call_driver
	ret

dev_list_print:
	ld	ix,(dev_start_ptr)
dev_list_loop:
	push	ix
	pop	hl
	ld	a,h
	or	l
	jp	z,dev_list_end
	
	ld	a,(ix+dev_struct_id)
	call	print_hex_8
	ld	a,' '
	call	console_outb

	ld	a,(ix+dev_struct_flags)
	call	print_hex_8
	ld	a,' '
	call	console_outb

	ld	a,(ix+dev_struct_block_size)
	call	print_hex_8
	ld	a,' '
	call	console_outb

	ld	l,(ix+dev_struct_driver)
	ld	h,(ix+dev_struct_driver+1)
	call	print_hex_16
	ld	a,' '
	call	console_outb

	ld	l,(ix+dev_struct_next_ptr)
	ld	h,(ix+dev_struct_next_ptr+1)
	call	print_hex_16
	ld	a,' '
	call	console_outb
	push	hl

	push	ix
	pop	hl
	ld	bc,dev_struct_name
	adc	hl,bc
	call	console_outs

	ld	a,'\n'
	call	console_outb

	pop	ix

	jp	dev_list_loop

dev_list_end:
	ret

