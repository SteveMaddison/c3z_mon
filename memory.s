;
; Memory management
;
; Steve Maddison, 24/02/2007
;

mem_init:	ld	hl,mem_heap
		ld	(mem_heap_ptr),hl
		ret

; Name: mem_heap_alloc
; Desc: Allocate memory from the heap
; In:	BC = bytes to allocate
; Out:	HL = address of allocated block
mem_heap_alloc:
		ld	hl,(mem_heap_ptr)
		push	hl
		and	a
		adc	hl,bc
		ld	(mem_heap_ptr),hl
		pop	hl
		ret

; Name:	memcmp
; Desc:	Compare first n bytes of buffers
; In:	HL, DE = addresses of buffers to compare
;	BC = number of bytes to check (n)
; Out:	Zero flag set if buffers match
memcmp:
	ld	a,b			; check if counter is 0
	or	c
	jp	z,memcmp_end
	ld	a,(de)			; compare bytes
	cp	(hl)
	jp	nz,memcmp_end
	inc	de
	inc	hl
	dec	bc
	jp	memcmp
memcmp_end:
	ret

