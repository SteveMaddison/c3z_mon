;
; Test harness for IDE driver
;
; Steve Maddison, 08/03/2007
;

status_init:		defm	"Testing init\n\0"
status_id:		defm	"Testing ide_get_id\n\0"
status_name:		defm	"Testing ide_get_name\n\0"
status_read:		defm	"Testing ide_sector_read\n\0"
status_write:		defm	"Testing ide_sector_write\n\0"

error_compare:		defm	"Compare error at offset 0x\0"
error_timeout:		defm	"Timeout\n\0"
error_general:		defm	"--Error: \0"

test_sector_msw:	equ	0x0000
test_sector_lsw:	equ	0x0246

buffer1:		equ	0x8000
buffer2:		equ	buffer1 + 512


ide_test:
		; Test init
		;ld	hl,status_init
		;call	console_outs
		;call	ide_init

		; Set config for further tests
		ld	a,ide_config_master
		ld	(ide_config),a

		; Test ID
		ld	hl,status_id
		call	console_outs
		ld	hl,0	; Use internal buffer
		call	ide_get_id
		jp	nz,error
		call	hexdump_512
		ld	a,'\n'
		call	console_outb

		; Test Name
		;ld	hl,status_name
		;call	console_outs
		;call	ide_get_name
		;jp	nz,error
		;ld	a,'"'
		;call	console_outb
		;call	console_outs
		;ld	a,'"'
		;call	console_outb

		; Fill a buffer with known values
		ld	hl,buffer1
		ld	a,65
		ld	b,0
fill_buffer_loop:
		ld	(hl),a
		inc hl
		inc	a
		ld	(hl),a
		inc hl
		inc	a
		djnz	fill_buffer_loop

		; Test write
		ld	hl,status_write
		call	console_outs
		ld	hl,buffer1
		ld	bc,test_sector_msw
		ld	de,test_sector_lsw
		call	ide_sector_write
		jp	nz,error
		ld	a,'\n'
		call	console_outb
		ld	hl,buffer1
		call	hexdump_512

		; Test read
		ld	hl,status_read
		call	console_outs
		ld	hl,buffer2
		ld	bc,test_sector_msw
		ld	de,test_sector_lsw
		call	ide_sector_read
		jp	nz,error
		ld	a,'\n'
		call	console_outb
		ld	hl,buffer2
		call	hexdump_512

		; Compare buffers
		ld	hl,buffer1
		ld	de,buffer2
		ld	b,0
compare_loop:	; First byte
		ld	a,(hl)
		ld	c,a
		ld	a,(de)
		cp	c
		jp	nz,compare_error
		inc	hl
		inc	de
		; Second byte
		ld	a,(hl)
		ld	c,a
		ld	a,(de)
		cp	c
		jp	nz,compare_error
		inc	hl
		inc	de
		djnz	compare_loop

		jp	end

compare_error:
		ld	hl,error_compare
		call	console_outs
		push	de
		pop	hl
		call	print_hex_16
		ld	a,'\n'
		call	console_outb

		jp	end
error:
		jp	nc,lookup
		ld	hl,error_timeout
		call	console_outs
		jp	end
lookup:
		ld	hl,error_general
		call	console_outs
		call	print_hex_8
end:	
		halt

; real subs
hexdump_512:
		ld	c,32
hexdump_row:
		; Output address of first byte in this row
		call	print_hex_16
		ld	a,':'
		call	console_outb
		ld	a,' '
		call	console_outb

		; Output hex value of each byte
		push	hl	; Save HL for ASCII output later
		ld	b,16
hexdump_val:
		ld	a,(hl)
		call	print_hex_8
		ld	a,' '
		call	console_outb
		; After 8th character, print a double space
		ld	a,b
		cp	9
		jp	nz,hexdump_val_next
		ld	a,' '
		call	console_outb
hexdump_val_next:
		inc	hl
		djnz	hexdump_val

		; Output ASCII representation delimited by '|' characters.
		ld	a,'|'
		call	console_outb
		pop	hl	; Restore HL
		ld	b,16
hexdump_char:
		; Only chars 0x20 - 0x7e are printable
		ld	a,(hl)
		cp	0x20
		jp	c,hexdump_char_non_printable
		cp	0x7e
		jp	nc,hexdump_char_non_printable
		jp	hexdump_char_print
hexdump_char_non_printable:
		; Non-printable characters are represented by a '.'
		ld	a,'.'
hexdump_char_print:
		call	console_outb
		inc	hl
		djnz	hexdump_char
		
		; Finish of printing the row
		ld	a,'|'
		call	console_outb
		ld	a,'\n'
		call	console_outb

		dec	c
		ld	a,c
		cp	0
		jp	nz,hexdump_row	; Next row
		ret

