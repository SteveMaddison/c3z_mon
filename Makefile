TARGETS=monitor.obj
SRCS=main.s intr.s uart.s

all:		${TARGETS}

clean:
		rm -f ${TARGETS}

monitor.obj:	$(SRCS)
		z80asm -o $@ $<
		@ls -l $@ | awk '{print $$8 ": " $$5 " bytes"}'

