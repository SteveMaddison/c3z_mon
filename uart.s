; UART ports: Base address is 0x20, total of 8 ports in use
uart_rbr:	equ	0x20	; RX Buffer/TX Holding Register
uart_ier:	equ	0x21	; Interrupt Enable Register
uart_iir:	equ	0x22	; Interrupt Identifier Register
uart_fcr:	equ	0x22	; FIFO Control Register
uart_lcr:	equ	0x23	; Line Control Register
uart_mcr:	equ	0x24	; Modem Control Register
uart_lsr:	equ	0x25	; Line Status Register
uart_msr:	equ	0x26	; Modem Status Register
uart_scr:	equ	0x27	; Scratch Register
uart_dll:	equ	0x20	; Divisor Latch LSB (when DLAB=1 in LCR)
uart_dlm:	equ	0x21	; Divisor Latch MSB (when DLAB=1 in LCR)

uart_dev_name:	defm	"ser0\0"

uart_driver:	defw	uart_rx
		defw	uart_tx

; Initialise the UART
uart_init:	push	af
		ld	a,0x00		; disable all interrupts
		;ld	a,0x05		; enable all RX interrupts
		out	(uart_ier),a
		;ld	a,0x0f		; enable and reset all FIFOs
		;out	(uart_fcr),a
		ld	a,0x80		; Set DLAB
		out	(uart_lcr),a
		ld	a,12		; Divisor of 12 = 9600 bps with 1.8432 MHz clock
		out	(uart_dll),a
		ld	a,00
		out	(uart_dlm),a
		ld	a,0x03		; 8 bits, 1 stop, no parity (and clear DLAB)
		out	(uart_lcr),a	; write new value back

		; Add a new device
		ld	a,0			; ID
		ld	b,dev_flag_char		; Flags
		ld	de,uart_driver		; Driver
		ld	hl,uart_dev_name	; Name
		call	dev_add

		pop	af
		ret

; uart_rx
; Wait for a byte from the UART, and save it in A
uart_rx:	call	uart_rx_ready
		in	a,(uart_rbr)
		ret

; uart_rx_ready
; Returns when UART has received data
uart_rx_ready:
		push	af
uart_rx_ready_loop:
		in	a,(uart_lsr)	; fetch the conrtol register
		bit	0,a		; bit will be set if UART has data
		jp	z,uart_rx_ready_loop
		pop	af
		ret

; uart_tx
; Sends byte in A to the UART
uart_tx:	call	uart_tx_ready
		cp	'\n'			; Newlines are replaced with
		jp	nz,uart_tx_send		; carriage returns so things
		ld	a,'\r'			; are displayed right on the
uart_tx_send:					; terminal emulator.
		out	(uart_rbr),a
uart_tx_end:
		ret

; uart_tx_str
; Sends null-terminated string starting at HL to UART
; XXX - can maybe optimised using CPI instruction?
uart_tx_str:	
		push	af
uart_tx_str_loop:
		ld	a,(hl)
		cp	0
		jp	z,uart_tx_str_end
		call	uart_tx
		inc	hl
		jp	uart_tx_str_loop
uart_tx_str_end:
		pop	af
		ret

; uart_tx_ready
; Returns when UART is ready to receive
uart_tx_ready:
		push	af
uart_tx_ready_loop:
		in	a,(uart_lsr)	; fetch the control register
		bit	5,a		; bit will be set if UART is ready
		jp	z,uart_tx_ready_loop
		pop	af
		ret

