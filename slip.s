;
; SLIP driver for the Z80
; http://www.cosam.org/projects/z80/
;
; Implements Serial Line IP as per RFC 1055
;
; Steve Maddison, 04/01/2008
;

; The framing characters
slip_char_end:		equ	0xc0	; 0300
slip_char_esc:		equ	0xdb	; 0333
slip_char_esc_end:	equ	0xdc	; 0334
slip_char_esc_esc:	equ	0xdd	; 0335

slip_dev_name:		defm	"slip0\0"

slip_driver:		defw	slip_datagram_rx
			defw	slip_datagram_tx

; Name: slip_check_datagram_size
; Desc: Check for maximum datagram size
; In:	DE = size to test
; Out:	CF = set if DE > maximum
slip_check_datagram_size:
		push	hl		; save
		push	bc		; save
		push	de
		pop	hl
		and	a		; clear CF (but keep A)
		ld	bc,slip_buffer_size
		sbc	hl,bc
		pop	bc		; restore
		pop	hl		; restore
		ret

; Name: slip_datagram_rx
; Desc: Receive a datagram from the serial port, de-framing on the fly.
; In:   HL = input buffer address (or 0 for internal buffer)
; Out:	DE = bytes written to buffer
;       CF = set if datagram was too large
slip_datagram_rx:
		call	slip_set_buffer
		ld	d,0
		ld	e,0
slip_datagram_rx_loop:
		call	uart_rx
slip_datagram_rx_check_end:
		cp	slip_char_end
		jp	z,slip_datagram_rx_success
slip_datagram_rx_check_esc:
		cp	slip_char_esc
		jp	nz,slip_datagram_rx_default
		; We got an escape, so fetch the escaped character
		call	uart_rx
slip_datagram_rx_check_esc_end:
		cp	slip_char_esc_end
		jp	nz,slip_datagram_rx_check_esc_esc
		ld	a,slip_char_end
slip_datagram_rx_check_esc_esc:
		cp	slip_char_esc_esc
		jp	nz,slip_datagram_rx_default
		ld	a,slip_char_esc
slip_datagram_rx_default:
		; Checking for a too-large datagram can only be done after we know
		; we actually want to write something to the buffer.
		call	slip_check_datagram_size
		jp	c,slip_datagram_rx_end
		ld	(hl),a
		inc	hl
		inc	de
		jp	slip_datagram_rx_loop
slip_datagram_rx_success:
		xor	a
slip_datagram_rx_end:
		ret

; Name: slip_datagram_tx
; Desc: Send a datagram to the serial port, framing on the fly,
;       including the terminating "end" character.
; In:   HL = start of datagram
;       DE = length of datagram
; Out:	ZF = set on success, clear on error
;	A = 0 on success, 1 if datagram too large
slip_datagram_tx:
		call	slip_check_datagram_size
		jp	nc,slip_datagram_tx_size_ok
		ld	a,1				; clear zero flag
		and	a
		jp	slip_datagram_tx_end
slip_datagram_tx_size_ok:
		call	slip_tx_data
		jp	nz,slip_datagram_tx_end		; bail out
		call	slip_datagram_tx_terminate
		xor	a
slip_datagram_tx_end:
		ret

; Name: slip_tx_data
; Desc: Send raw data to the serial port, framing on the fly,
;	without the terminating end character.
; In:   HL = start of data
;       DE = length of data
; Out:	ZF = set on success, clear on error
slip_tx_data:
slip_tx_data_loop:
		ld	a,d
		or	e
		jp	z,slip_tx_data_end
		ld	a,(hl)
slip_tx_data_check_end:
		cp	slip_char_end
		jp	nz,slip_tx_data_check_esc
		ld	a,slip_char_esc
		call	uart_tx
		ld	a,slip_char_esc_end
		call	uart_tx
		jp	slip_tx_data_sent
slip_tx_data_check_esc:
		cp	slip_char_esc
		jp	nz,slip_tx_data_default
		ld	a,slip_char_esc
		call	uart_tx
		ld	a,slip_char_esc_esc
		call	uart_tx
		jp	slip_tx_data_sent
slip_tx_data_default:
		call	uart_tx		; byte to send is still in A
slip_tx_data_sent:
		inc	hl
		dec	de
		jp	slip_tx_data_loop
slip_tx_data_end:
		ret

; Name: slip_datagram_tx_terminate
; Desc: Send the terminating "end" character
slip_datagram_tx_terminate:
		ld	a,slip_char_end
		call	uart_tx
		ret

; Name: slip_get_buffer
; Desc: Return address of internal buffer
; Out:	HL = buffer address;
slip_get_buffer:
		ld	hl,slip_internal_buffer
		ret

; Name: slip_init
; Desc: Initialise SLIP device
slip_init:
		; Add a new device
		ld	a,0			; ID
		ld	b,dev_flag_char		; Flags
		ld	de,slip_driver		; Driver
		ld	hl,slip_dev_name	; Name
		call	dev_add

; Name: slip_set_buffer
; Desc:	Check for magic buffer address (0)
; In:	HL = proposed buffer address
; Out:	HL = actual buffer address
slip_set_buffer:
		ld	a,h
		or	l
		jp	nz,slip_set_buffer_end
		ld	hl,slip_internal_buffer
slip_set_buffer_end:
		ret
