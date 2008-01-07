;
; Memory management
;
; Steve Maddison, 24/02/2007
;

mem_banner:	defm	"K RAM\0"

mem_init:	
		ld	hl,ram_start
mem_init_loop:
		; Check for working memory at 256-byte intervals
		; by writing, then reading back a known value.
		ld	(hl),0xaa
		ld	a,(hl)
		cp	0xaa
		jp	nz,mem_init_end
		inc	h
		ld	a,h	; Past end of possible RAM?
		cp	0
		jp	nz,mem_init_loop
mem_init_end:
		push	hl
		ld	bc,ram_start
		and	a
		sbc	hl,bc
		ld	a,h
		srl	a
		srl	a
		call	print_int_8
		ld	hl,mem_banner
		call	console_outs
		pop	hl
		dec	hl
		ret

