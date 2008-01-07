;
; IDE interface driver
;
; Steve Maddison, 06/03/2007
;

; The IDE interface makes use of three I/O ports; two for the 16-bit IDE
; data bus and one for the remaining address and CS signals (referred to
; here as the "control" port).
ide_data_lsb:		equ	0x40
ide_data_msb:		equ	0x41
ide_control:		equ	0x42

ide_dev_name_master:	defm	"hd0\0"
ide_dev_name_slave:	defm	"hd1\0"

ide_driver:		defw	ide_sector_read
			defw	ide_sector_write
			defw	ide_get_size
			defw	ide_get_buffer

; IDE Regsiters (values for the control port)
; Bit 0-2 = Addr0-2, Bit 3 = /CS0, Bit 4 = /CS1
ide_reg_data:		equ	0x10	; 0: Data port
ide_reg_error:		equ	0x11	; 1: Error code is read-only
ide_reg_sectors:	equ	0x12	; 2: Sectors to transfer
; LBA sector address is a 28-bit value made up of the following 3 bytes
; and bits 0-3 of the fourth.
ide_reg_sector_0:	equ	0x13	; 3: low byte
ide_reg_sector_1:	equ	0x14	; 4: lower-middle byte
ide_reg_sector_2:	equ	0x15	; 5: upper-middle byte
ide_reg_sector_3:	equ	0x16	; 6: bits 0-3 high nibble
ide_reg_config:		equ	ide_reg_sector_3
; Following register has two purposes
ide_reg_status:		equ	0x17		; When read
ide_reg_command:	equ	ide_reg_status	; When written

; IDE error codes.
ide_error_none:		equ	0x00
ide_error_none_str:	defm	"No error (timeout?)\0"
ide_error_dam:		equ	0x01
ide_error_dam_str:	defm	"DAM not found\0"
ide_error_track:	equ	0x02
ide_error_track_str:	defm	"Track 000 not found\0"
ide_error_abort:	equ	0x04
ide_error_abort_str:	defm	"Command aborted\0"
ide_error_id:		equ	0x10
ide_error_id_str:	defm	"ID not found\0"
ide_error_ecc:		equ	0x40
ide_error_ecc_str:	defm	"Unrecoverable ECC error\0"
ide_error_block:	equ	0x80
ide_error_block_str:	defm	"Bad block detected\0"
ide_error_bogus_str:	defm	"Bogus error code\0"
; Table of error strings, indexed by bit set in error code.
ide_error_str_table:	defw	ide_error_none_str	; 0
			defw	ide_error_dam_str	; 1
			defw	ide_error_track_str	; 2
			defw	ide_error_bogus_str	; 3 (reserved)
			defw	ide_error_id_str	; 4
			defw	ide_error_bogus_str	; 5 (reserved)
			defw	ide_error_ecc_str	; 6
			defw	ide_error_ecc_str	; 7

; Masks for remaining bits (4-8) of register 6
ide_config_base:	equ	0xa0	; "Always on" bits
ide_config_master:	equ	0x00	; Access master device
ide_config_slave:	equ	0x10	; Access slave device
ide_config_lba:		equ	0x40	; Enable LBA

; Masks for bits in status register
ide_status_error:	equ	0x01	; Last command resulted in error
ide_status_drq:		equ	0x08	; Data Request Ready (sector buffer ready)
ide_status_df:		equ	0x20	; Write fault
ide_status_rdy:		equ	0x40	; Ready for command
ide_status_busy:	equ	0x80	; Executing command

; IDE commands
ide_cmd_read:		equ	0x20	; Read sectors with retry
ide_cmd_write:		equ	0x30	; Write sectors with retry
ide_cmd_id:		equ	0xec	; Identify device

; Offsets into IDE device identification info
ide_info_name:		equ	0x36
ide_info_name_len:	equ	40
ide_info_size:		equ	0x72	; Two 16-bit words, least significant first

; Initialisation messages
ide_init_header:	defm	"IDE devices\n\0";
ide_init_master:	defm	" Master: \0"
ide_init_slave:		defm	" Slave : \0"
ide_init_none:		defm	"none\0"

; Timeout values used when checking device is ready.
ide_timeout_count:	equ	0xffff	; Number of times to loop (16-bit)
ide_timeout_res:	equ	20	; Time to wait each loop (8-bit)


; Name:	ide_block_read
; Desc: Read one block (256 words) from IDE device.
; In:	HL = start of input buffer.
ide_block_read:
		ld	a,ide_reg_data
		out	(ide_control),a
		push	hl
		pop	ix
		ld	b,0	; loop 256 times 
ide_block_read_loop:
		in	a,(ide_data_lsb)
		ld	(ix+1),a
		in	a,(ide_data_msb)
		ld	(ix+0),a
		inc	ix
		inc	ix
		djnz	ide_block_read_loop
		ret

; Name: ide_block_write
; Desc:	Write one block (256 words) to IDE device.
; In:	HL = start of output buffer.
ide_block_write:
		ld	a,ide_reg_data
		out	(ide_control),a
		ld	b,0	; loop 256 times 
ide_block_write_loop:
		ld	a,(hl)
		out	(ide_data_msb),a
		inc	hl
		ld	a,(hl)
		out	(ide_data_lsb),a
		inc	hl
		djnz	ide_block_write_loop
		ret

; Name: ide_check_error
; Desc: Check for error condition.
; In:	none
; Out:	ZF = 1 on success, otherwise 1
; 	A  = IDE error code.
ide_check_error:
		; Fetch the status and check for error flag
		call	ide_get_status
		and	ide_status_error
		jp	z,ide_check_error_end
		; Fetch the error code
		ld	a,ide_reg_error
		out	(ide_control),a
		in	a,(ide_data_lsb)
ide_check_error_end:
		ret

; Name:	ide_config_check
; Desc:	Sanitise saved configuration parameters.
ide_config_check:
		ld	a,(ide_config)		; Load value for sanitising
		and	0xf0			; Clear lower nibble
		or	ide_config_base	| ide_config_lba
		ld	(ide_config),a		; Save result
		ret

; Name:	ide_error_str
; Desc:	Get error string for an IDE error code (if multiple bits are
;	set, the error string corresponding to the least significant
;	bit is returned).
; In:	A = IDE error code
; Out:	HL = Corresponding error string
ide_error_str:
		push	bc
		ld	hl,ide_error_str_table
		cp	0	; No error
		jp	z,ide_error_str_end
		ld	b,8	; There are 8 bits to check
ide_error_str_loop:
		inc	hl	; Point to next error string
		inc	hl
		cp	0x01	; LSB set?
		jp	z,ide_error_str_end
		rra
		djnz	ide_error_str_loop
ide_error_str_end:
		pop	bc
		ret

; Name: ide_get_buffer
; Desc: Return address of internal buffer
; Out:	HL = buffer address;
ide_get_buffer:
		ld	hl,ide_internal_buffer
		ret

; Name:	ide_get_id
; Desc:	Fetch device identifier.
; In:	HL = address of input buffer (0 for internal buffer)
; Out:	ZF = 1 on success,
;	CF = 1 if timed out,
; 	A  = IDE error code,
;	HL = address of input buffer
ide_get_id:
		call	ide_set_buffer
		push	hl			; Remember value
		call	ide_ready
		jp	nz,ide_get_id_end	; Timeout
		call	ide_config_check
		ld	a,ide_reg_config	; Set config
		out	(ide_control),a
		ld	a,(ide_config)
		out	(ide_data_lsb),a
		ld	a,ide_cmd_id		; Send command
		call	ide_send_command
		call	ide_ready_data		; Wait for DRQ
		jp	nz,ide_get_id_end	; Timeout
		call	ide_check_error		; Check for error
		jp	nz,ide_get_id_end	; Bail out - A = error code
		call	ide_block_read		; Read buffer
ide_get_id_end:
		pop	hl			; Restore value
		ret

; Name:	ide_get_name
; Desc:	Return a trimmed, null-terminated version of the device
;	name as found in the identifier info.
; In:	none
; Out:	ZF = 1 on success,
; 	A  = IDE error code,
; 	HL = address of string
ide_get_name:
		push	bc
		ld	hl,0	; Use internal buffer
		call	ide_get_id
		jp	nz,ide_get_name_end
		jp	c,ide_get_name_end
		; Write a 0 after the end of the field, just in case all
		; characters are in use.
		ld	hl,ide_info_name + ide_info_name_len + ide_internal_buffer
		ld	(hl),0

		ld	b,ide_info_name_len	; Keep count, in case the field
						; is nothing but spaces!
ide_get_name_trim:
		dec	hl
		ld	a,(hl)
		cp	0x20
		jp	nz,ide_get_name_ok
		ld	(hl),0
		djnz	ide_get_name_trim
ide_get_name_ok:
		xor	a	; set zero flag
		; Point HL to start of string
		ld	hl,ide_info_name + ide_internal_buffer
ide_get_name_end:
		pop	bc
		ret

; Name: ide_get_size
; Desc: Fetch size of device in blocks
; In:	A = IDE device ID
; Out:	BCDE = Number of blocks,
;	ZF   = 1 on success,
;	A    = IDE error code.
ide_get_size:
		ld	(ide_config),a
		ld	hl,0	; Use internal buffer
		call	ide_get_id
		jp	nz,ide_get_size_end
		jp	c,ide_get_size_end
		ld	a,(ide_info_size + ide_internal_buffer)
		ld	d,a
		ld	a,(ide_info_size + ide_internal_buffer + 1)
		ld	e,a
		ld	a,(ide_info_size + ide_internal_buffer + 2)
		ld	b,a
		ld	a,(ide_info_size + ide_internal_buffer + 3)
		ld	c,a
		xor	a
ide_get_size_end:
		ret
		
; Name: ide_get_status
; Desc:	Fetch contents of the status register
; In:	none
; Out:	A = contents of IDE status register
ide_get_status:	
		ld	a,ide_reg_status
		out	(ide_control),a
		in	a,(ide_data_lsb)
		ret

; Name:	ide_init
; Desc:	Initialise and list devices
ide_init:
		; Output header text
		ld	hl,ide_init_header
		call	console_outs
		; Info for master
		ld	hl,ide_init_master
		ld	a,ide_config_master
		call	ide_init_dev
		; Info for slave
		ld	hl,ide_init_slave
		ld	a,ide_config_slave
		call	ide_init_dev
		ret

; Name: ide_init_dev
; Desc: Helper for ide_init - scans for device, then initialises it and
;	prints an info line as necessary.
; In:	A  = IDE config parameters
;	HL = Address of string constant
;	IY = Device name
ide_init_dev:
		push	bc
		push	de
		call	console_outs
		ld	(ide_config),a
		call	ide_config_check
		ld	b,10			; Try ten times
ide_init_dev_get_name:
		call	ide_get_name
		jp	z,ide_init_dev_found
		djnz	ide_init_dev_get_name
		jp	nc,ide_init_dev_error
		ld	hl,ide_init_none
		jp	ide_init_dev_print
ide_init_dev_error:
		call	ide_error_str
		jp	ide_init_dev_print
ide_init_dev_found:
		push	hl
		; Add a new device
		ld	a,(ide_config)
		and	ide_config_slave
		jp	nz,ide_init_dev_slave
		ld	hl,ide_dev_name_master
		jp	ide_init_dev_add
ide_init_dev_slave:
		ld	hl,ide_dev_name_slave
ide_init_dev_add:
		ld	a,(ide_config)		; ID
		ld	b,dev_flag_block	; Flags
		ld	c,0x02			; Block size (512 >> 8)
		ld	de,ide_driver		; Driver
		call	dev_add
		pop	hl
ide_init_dev_print:
		call	console_outs
		ld	a,'\n'
		call	console_outb
		pop	de
		pop	bc
		ret
		
; Name: ide_ready
; Desc:	Wait until device is ready.
; Out:	ZF = 1 on success, 0 if timed out.
;	CF = 1 on timeout
ide_ready:
		push	bc
		; Check BUSY=0 and RDY=1
		ld	c,ide_status_busy & ~ide_status_rdy
		call	ide_wait
		pop	bc
		ret

; Name: ide_ready_data
; Desc:	Wait until device is ready to send/receive data.
; Out:	ZF = 1 on success, 0 if timed out.
;	CF = 1 on timeout
ide_ready_data:
		push	bc
		; Check BUSY=0 and DRQ=1
		ld	c,ide_status_busy & ~ide_status_drq
		call	ide_wait
		pop	bc
		ret

; Name: ide_sector_count
; Desc: Set IDE sector count register (currently always
;	to "1", although this could be parameterised).
ide_sector_count:
		ld	a,ide_reg_sectors
		out	(ide_control),a
		ld	a,1
		out	(ide_data_lsb),a
		ret

; Name:	ide_sector_read
; Desc:	Read one sector from device.
; In:	A    = IDE device ID
; 	BCDE = Sector index as per ide_sector_select,
; 	HL   = address of input buffer (0 for internal buffer)
; Out:	ZF = 1 on success,
;	CF = 1 if timed out,
; 	A  = IDE error code,
;	HL = address of input buffer
ide_sector_read:
		ld	(ide_config),a
		call	ide_set_buffer
		push	hl				; Remember values
		call	ide_ready			; Wait until device is ready
		jp	nz,ide_sector_read_error	; Timeout
		call	ide_sector_select		; Program sector index
		call	ide_sector_count		; Set sector count
		ld	a,ide_cmd_read			; Send read command
		call	ide_send_command
		call	ide_ready_data			; Wait until data is ready
		jp	nz,ide_sector_read_error	; Timeout
		call	ide_check_error
		jp	nz,ide_sector_read_error
		pop	hl
		push	hl
		call	ide_block_read			; Copy the data to our buffer
ide_sector_read_error:
		pop	hl				; Restore value
		ret

; Name: ide_sector_select
; Desc: Send LBA 28-bit sector address to the appropriate IDE registers.
; In:	BCDE = sector address, E being least significant. Only the least
; 	significant nibble of B is used.
ide_sector_select:
		ld	a,ide_reg_sector_0
		out	(ide_control),a
		ld	a,e
		out	(ide_data_lsb),a

		ld	a,ide_reg_sector_1
		out	(ide_control),a
		ld	a,d
		out	(ide_data_lsb),a

		ld	a,ide_reg_sector_2
		out	(ide_control),a
		ld	a,c
		out	(ide_data_lsb),a

		ld	a,ide_reg_sector_3
		out	(ide_control),a
		ld	a,b
		and	0x0f			; clear top nibble
		ld	b,a
		call	ide_config_check
		or	b
		out	(ide_data_lsb),a
		ret

; Name:	ide_sector_write
; Desc:	Write one sector to the device.
; In:	A    = IDE device ID
;	BCDE = Sector index as per ide_sector_select,
; 	HL   = address of output buffer.
; Out:	ZF = 1 on success,
;	CF = 1 if timed out,
; 	A  = IDE error code.
ide_sector_write:
		ld	(ide_config),a
		push	hl				; Remember values
		call	ide_ready			; Wait until device is ready
		jp	nz,ide_sector_write_error	; Timeout
		call	ide_sector_select		; Program sector index
		call	ide_sector_count		; Set sector count
		ld	a,ide_cmd_write			; Send write command
		call	ide_send_command
		call	ide_ready_data			; Wait until device is ready for data
		jp	nz,ide_sector_write_error	; Timeout
		pop	hl
		push	hl
		call	ide_block_write			; Copy our data to the device
		call	ide_ready			; Wait until device is ready
		jp	nz,ide_sector_write_error	; Timeout
		call	ide_check_error
ide_sector_write_error:
		pop	hl			; Restore value
		ret

; Name:	ide_send_command
; Desc: Send a command to the device
; In:	A = IDE command code
ide_send_command:
		push	af
		ld	a,ide_reg_command
		out	(ide_control),a
		pop	af
		out	(ide_data_lsb),a
		ret

; Name: ide_set_buffer
; Desc:	Check for magic buffer address (0)
; In:	HL = proposed buffer address
; Out:	HL = actual buffer address
ide_set_buffer:
		ld	a,h
		or	l
		jp	nz,ide_set_buffer_end
		ld	hl,ide_internal_buffer
ide_set_buffer_end:
		ret

; Name: ide_wait
; Desc:	Wait for given value of status register, with timeout.
; In:	C = mask to AND with register, such that a result of zero
;	indicates success.
; Out:	ZF = 1 on success, 0 if timed out,
;	CF = 1 if timed out
ide_wait:
		push	hl
		push	de
		and	a
		ld	de,ide_timeout_count
ide_wait_loop:
		call	ide_get_status
		ld	h,a
		and	c
		jp	z,ide_wait_end
		ld	b,ide_timeout_res
ide_wait_pause:
		djnz	ide_wait_pause
		dec	de
		ld	a,d
		or	e
		jp	nz,ide_wait_loop
		ld	a,h
		; Timeout - clear zero flag, set carry flag
		ld	a,1
		and	a
		scf	
ide_wait_end:
		pop	de
		pop	hl
		ret

