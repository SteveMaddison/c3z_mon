TARGETS=monitor.obj
SRCS=main.s cli.s crash.s error.s float.s int.s memmap.s memory.s print.s uart.s

all:		${TARGETS}

clean:
		rm -f ${TARGETS}

monitor.obj:	$(SRCS)
		z80asm -o $@ $<
		@ls -l $@ | awk '{print $$8 ": " $$5 " bytes"}'

dump:		$(TARGETS)
		hexdump -C $<

