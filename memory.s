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

