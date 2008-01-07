TARGETS=monitor.obj
SRCS=main.s uart.s calc.s memmap.s cli.s

all:		${TARGETS}

clean:
		rm -f ${TARGETS}

monitor.obj:	$(SRCS)
		z80asm -o $@ $<
		@ls -l $@ | awk '{print $$8 ": " $$5 " bytes"}'

