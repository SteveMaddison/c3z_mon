;
; Interrupt table and associated routines
;
; Steve Maddison, 12/02/2007
;

; For Mode 1:
; Interrupt handler is located at 0x38
intr_mode1:	defm 	"ABCD"
		reti

intr_init:
intr_init_1:
		im	1
		ei
		ret

; For Mode 2:
; Table containing instuctions executed when an interrupt occurs. All are
; direct jumps to the relevant handling routines provided by the device
; drivers. Each jump (3 bytes) is followed by a NOP in order to maintain
; a count of four bytes per table entry. The table is padded out in order
; to reserve space for all 8 IRQs.
; The encoded IRQ is delivered to the data bus on bits 2 thru 4 with bit
; 5 always high. This means that the data bus carries (IRQ * 4) + 0x20.
intr_table:	jp	intr_dummy	; IRQ 0 (Data bus = 0x20)
		nop
		jp	intr_dummy	; IRQ 1 (Data bus = 0x24)
		nop
		jp	intr_dummy	; IRQ 2 (Data bus = 0x28)
		nop
		jp	intr_dummy	; IRQ 3 (Data bus = 0x2c)
		nop
		jp	intr_dummy	; IRQ 4 (Data bus = 0x30)
		nop
		jp	intr_dummy	; IRQ 5 (Data bus = 0x24)
		nop
		jp	intr_dummy	; IRQ 6 (Data bus = 0x28)
		nop
		jp	intr_dummy	; IRQ 7 (Data bus = 0x2c)
		nop

; Place the MSB of the interrupt table in I and set the interrupt mode.
intr_init_2:	ld	a,0
		ld	i,a
		im	2

; Dummy target for unused IRQs
intr_dummy:	reti

