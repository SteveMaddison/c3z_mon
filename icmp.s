;
; Internet Control Message Protocol (RFC 792)
;
; Steve Maddison, 08/01/2008
;

; Name: icmp_rx
; Desc: Process ICMP message
; In:	HL = Address of data buffer
;	DE = Data length
;	IX = Address op IP header
icmp_rx:
	ret
