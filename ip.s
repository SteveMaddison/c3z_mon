;
; Internet Protocol (RFC 791)
;
; Steve Maddison, 05/01/2008
;

; Offsets into IP datagram header, in bytes, with masks
; for fields that share bytes with others.
ip_hdr_version:		equ	0
ip_hdr_version_mask:	equ	0xf0
ip_hdr_version_shift:	equ	4
ip_hdr_ihl:		equ	0
ip_hdr_ihl_mask:	equ	0x0f
ip_hdr_tos:		equ	1
ip_hdr_length:		equ	2
ip_hdr_ident:		equ	4
ip_hdr_flags:		equ	6
ip_hdr_flags_mask:	equ	0xe0
ip_hdr_fragment:	equ	6
ip_hdr_fragment_mask:	equ	0x1fff
ip_hdr_ttl:		equ	8
ip_hdr_protocol:	equ	9
ip_hdr_checksum:	equ	10
ip_hdr_src_addr:	equ	12
ip_hdr_dest_addr:	equ	16
ip_hdr_options:		equ	20
ip_hdr_padding:		equ	23

; We need to know some protocol numbers to demultiplex
; incoming traffic.
ip_proto_ip:		equ	0
ip_proto_icmp:		equ	1
ip_proto_tcp:		equ	6
ip_proto_udp:		equ	17

; IP configuration values
ip_version:		equ	4
ip_tos_default:		equ	0
ip_flags_default:	equ	0x00
ip_ttl_default:		equ	0xff		; High for now, can be decreased.
ip_ihl_min:		equ	5		; In 32-bit words
ip_ihl_max:		equ	6		; In 32-bit words
ip_addr_default:	defb	10,0,0,1	; 10.0.0.1
ip_broadcast_default:	defb	10,255,255,255	; 10.255.255.255
ip_net_loopback:				; 127(.0.0.0/8)
ip_addr_loopback:	defb	127,0,0,1	; (127).0.0.1


; Name: ip_calc_checksum
; Desc: Calculate the checksum for IP header
; In:	IX = start of data
;	BC = length of data
; Out:	HL = calculated checksum
ip_calc_checksum:
	push	ix	; save
	push	de	; save
	and	a	; clear CF
	push	af	; will be popped/pushed during loop
ip_calc_checksum_loop:
	ld	a,b
	or	c
	jp	z,ip_calc_checksum_end
	ld	d,(ix+0)
	ld	e,(ix+1)
	pop	af
	adc	hl,de
	push	af	; keep track of carry
	inc	ix
	inc	hl
	dec	bc
	dec	bc
	jp	ip_calc_checksum_loop
ip_calc_checksum_end:
	pop	af	; put stack right
	; Invert HL (1's complement)
	ld	a,h
	cpl
	ld	h,a
	ld	a,l
	cpl
	ld	l,a
	pop	de	; restore
	pop	ix	; restore
	ret

; Name: ip_check_dest
; Desc: Check if a packet is for this host
; In:	IX = address of IP header
; Out:	ZF = set if for this host, otherwise cleared
ip_check_dest:
	push	bc			; save
	push	de
	push	hl
	ld	bc,ip_addr_length	; for memcmp
	; Get destination address
	push	ix
	pop	hl
	ld	de,ip_hdr_dest_addr
	add	hl,de
	push	hl			; save destination address
	; Check IP address
	ld	de,ip_addr
	call	memcmp
	pop	hl			; restore destination address
	jp	z,ip_check_dest_end
	; Check broadcast address
	ld	de,ip_broadcast
	call	memcmp
ip_check_dest_end:	
	pop	hl			; restore
	pop	de
	pop	bc
	ret

; Name: ip_init
; Desc: Initialise the IP interface
ip_init:
	ld	hl,ip_addr_default
	call	ip_set_addr
	ld	hl,ip_broadcast_default
	call	ip_set_broadcast
	ret

; Name: ip_rx
; Desc: Process IP datagram received from a remote host
; In:	HL = Data buffer
ip_rx:
	; Set IX = IP header address
	push	hl
	pop	ix
	; Check TTL
	ld	a,(ix+ip_hdr_ttl)
	cp	0
	jp	z,ip_rx_discard
	; Check IHL is valid
	ld	a,(ix+ip_hdr_ihl)
	and	ip_hdr_ihl_mask
	cp	ip_ihl_min
	jp	c,ip_rx_discard
	; Check version
	ld	a,(ix+ip_version)
	and	ip_hdr_version_mask
	cp	ip_version << ip_hdr_version_shift
	jp	nz,ip_rx_discard
	; Convert IHL from words to bytes (*4)
	rla
	rla
	; Save 16-bit result in BC
	ld	b,0
	ld	c,a
	; Check checksum
	call	ip_calc_checksum
	ld	a,(ix+ip_hdr_checksum)
	cp	h
	jp	nz,ip_rx_discard
	ld	a,(ix+ip_hdr_checksum+1)
	cp	l
	jp	nz,ip_rx_discard
	; Check if packet if for this host
	call	ip_check_dest
	jp	nz,ip_rx_discard
	; Set HL = total length of IP datagram
	ld	h,(ix+ip_hdr_length+0)
	ld	l,(ix+ip_hdr_length+1)
	; Subtract from total length => payload length => DE
	and	a	; clear CF
	sbc	hl,bc
	push	hl
	pop	de
	; Add to buffer address => start of payload
	push	ix
	pop	hl
	add	hl,bc
	; Process the payload
	call	ip_rx_data
ip_rx_discard:
	ret

; Name: ip_rx_data
; Desc: Process payload of IP datagram after header has been checked
; In:	HL = Address of data buffer
;	DE = Data length
;	IX = Address op IP header
ip_rx_data:
	; Demuliplex according to protocol number. All protocol handlers
	; expect the same parameters in the same registers as this routine.
	ld	a,(ix+ip_hdr_protocol)
ip_rx_data_icmp:
	cp	ip_proto_icmp
	jp	nz,ip_rx_data_udp
	call	icmp_rx
	jp	ip_rx_data_end
ip_rx_data_udp:
	cp	ip_proto_udp
	jp	nz,ip_rx_data_tcp
;	call	udp_rx
	jp	ip_rx_data_end
ip_rx_data_tcp:
	cp	ip_proto_tcp
	jp	nz,ip_rx_data_end
;	call	tcp_rx
	jp	ip_rx_data_end
ip_rx_data_end:
	ret

; Name: ip_set_addr
; Desc: Set IP address
; In:   HL = address of address in network byte order
ip_set_addr:
	ld	de,ip_addr
	ld	bc,ip_addr_length
	ldir
	ret

; Name: ip_set_broadcast
; Desc: Set IP broadcast address
; In:   HL = address of address in network byte order
ip_set_broadcast:
	ld	ix,ip_broadcast
	ld	(ix+0),h
	ld	(ix+1),l
	inc	hl
	ld	(ix+2),h
	ld	(ix+3),l
	ret

; Name: ip_tx
; Desc: Transmit an IP datagram
; In:	BCDE = Destination IP address (in network byte order)
;       A = Protocol number
;       HL = Data buffer
;	IY = Data length
; Out:	CF = set on error
ip_tx:	
	push	iy		; save data length
	push	hl		; save buffer pointer
	push	de		; save destination address
	push	bc
	push	af		; save protocol number
	ld	ix,ip_hdr_scratch
	ld	a,ip_version << 4
	or	ip_ihl_min
	ld	(ix+ip_hdr_version),a
	ld	(ix+ip_hdr_tos),ip_tos_default
	; Calculate total length
	push	iy		; save data length to HL
	pop	hl
	ld	bc,ip_ihl_min*4	; calculate header length in bytes
	add	hl,bc		; add to data length
	ld	(ix+ip_hdr_length+0),h
	ld	(ix+ip_hdr_length+1),l
	; Check length with SLIP driver, as won't be sending the
	; whole datagram in one go.
	push	hl
	pop	de
	call	slip_check_datagram_size
	jp	nc,ip_tx_size_ok
	; Datagram is too large, so pop all our saved
	; parameters before bailing out
	pop	hl
	pop	hl
	pop	hl
	pop	hl
	pop	hl
	jp	ip_tx_end
ip_tx_size_ok:
	; More IP header fields...
	ld	(ix+ip_hdr_ident+0),0
	ld	(ix+ip_hdr_ident+1),0
	ld	(ix+ip_hdr_flags+0),ip_flags_default
	ld	(ix+ip_hdr_flags+1),0
	ld	(ix+ip_hdr_ttl),ip_ttl_default
	pop	af		; restore protocol number
	ld	(ix+ip_hdr_protocol),a
	; Source address
	push	ix
	pop	hl
	ld	bc,ip_hdr_src_addr
	add	hl,bc
	push	hl
	pop	de
	ld	hl,ip_addr	; already in network byte order
	ld	bc,ip_addr_length
	ldir
	; Destination address
	pop	hl		; restore destination address
	ld	(ix+ip_hdr_dest_addr+0),h
	ld	(ix+ip_hdr_dest_addr+1),l
	pop	hl
	ld	(ix+ip_hdr_dest_addr+2),h
	ld	(ix+ip_hdr_dest_addr+3),l
	; Headed for loopback address?
	ld	a,(ix+ip_hdr_dest_addr)
	cp	ip_net_loopback
	jp	nz,ip_tx_slip
	; Set source to loopback too
	ld	hl,ip_addr_loopback
	ld	(ix+ip_hdr_src_addr+0),h
	ld	(ix+ip_hdr_src_addr+1),l
	inc	hl
	ld	(ix+ip_hdr_src_addr+2),h
	ld	(ix+ip_hdr_src_addr+3),l
	pop	hl		; restore data pointer
	pop	de		; restore original data length
	call	ip_rx_data
	jp	ip_tx_end
ip_tx_slip:
	; Checksum - sneakily skipped for loopback packets (shhh!)
	call	ip_calc_checksum
	ld      (ix+ip_hdr_checksum+0),h
	ld      (ix+ip_hdr_checksum+1),l
	; Send header
	push	ix		; send header
	pop	hl
	ld	de,ip_ihl_min*4
	call	slip_tx_data
	; Send data
	pop	hl		; restore data pointer
	pop	de		; restore original data length
	call	slip_tx_data
	call	slip_datagram_tx_terminate
ip_tx_end:
	ret

