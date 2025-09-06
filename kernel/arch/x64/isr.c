#include <stddef.h>

#include "common/kernel.h"
#include "common/isr.h"
#include "common/serial.h"

void (*interruptHandlers[256])(struct InterruptFrame *frame);

void exceptionHandler(struct InterruptFrame *frame) {
    // printNumber(frame->int_no);
    // printNumber(frame->err_code);
	switch (frame->intNo) {
		case 14:
			if (frame->errCode & 1) {
				serialLogz("Page protection violation\r\n");
				hang();
			}
			
			serialLogz("\r\n\n\ndead :(\r\n");
			break;
	}
}

void registerInterruptHandler(uint8_t interrupt, void (*handler)(struct InterruptFrame *frame)) {
    interruptHandlers[interrupt] = handler;
}

void irqHandler(struct InterruptFrame *frame) {
	if (interruptHandlers[frame->intNo] != NULL) {
		interruptHandlers[frame->intNo](frame);
	}
}