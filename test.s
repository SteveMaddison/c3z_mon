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

		di
		ld	sp,0
		; Initialise the UART
		ld	a,0x00		; disable all interrupts
		out	(uart_ier),a
		ld	a,0x80		; Set DLAB
		out	(uart_lcr),a
		ld	a,96		; Divisor of 96 = 1200 bps with 1.8432 MHz clock
		out	(uart_dll),a
		ld	a,00
		out	(uart_dlm),a
		ld	a,0x03		; 8 bits, 1 stop, no parity (and clear DLAB)
		out	(uart_lcr),a	; write new value back

loop:
;read_loop:	in	a,(uart_lsr)
;		bit	0,a
;		jp	z,read_loop
;
;		in	a,(uart_rbr)	; get char
;		cp	'w'
;		jp	z,read_loop
;
write_loop:	in	a,(uart_lsr)
		bit	5,a
		jp	z,write_loop

		ld	a,'w'
		out	(uart_rbr),a
		jp	loop

