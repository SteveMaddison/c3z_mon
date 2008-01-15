TARGETS=monitor.bin
SRCS=main.s builtin.s cli.s crash.s device.s error.s float.s fs.s\
icmp.s ide.s int.s ip.s ll.s memmap.s memory.s print.s pseudo.s slip.s\
socket.s string.s uart.s udp.s

all:		${TARGETS}

clean:
		rm -f ${TARGETS}

monitor.bin:	$(SRCS)
		z80asm -o $@ $<
		@ls -l $@ | awk '{print "$@: " $$5 " bytes"}'

dump:		$(TARGETS)
		hexdump -C $<

