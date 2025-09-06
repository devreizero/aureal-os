#include <address.h>
#include <stdint.h>

#include "common/interrupt/idt.h"
#include "common/serial.h"

static struct IDTEntry entries[256];
static struct IDTDescriptor descriptor = (struct IDTDescriptor) {
    (Limit16) sizeof(entries) - 1,
    (VirtAddr) entries
};

extern void *isr_stub_table[];
extern void *irq_stub_table[];

void initIDT() {
    for (uint8_t i = 0; i < 32; i++)  {
        setIDTEntry32(entries + i, (Offset) isr_stub_table[i], 0x28, 0x8E);
    }

    for (uint8_t i = 32; i < 255; i++) {
        setIDTEntry32(entries + i, (Offset) irq_stub_table[i - 32], 0x28, 0x8E);
    }
    
    setIDTEntry32(entries + 255, (Offset) irq_stub_table[223], 0x28, 0x8E);

    __asm__ volatile("lidt %0" : : "m"(descriptor));
    __asm__ volatile("sti");

    serialLogz("IDT Initialized\r\n");
}

void setIDTEntry32(struct IDTEntry *target, Offset offset, IDTSegmentSelector segmentSelector, IDTTypeAttributes typeAttributes) {
    target->offsetLow = offset & 0xFFFF;
    target->segmentSelector = segmentSelector;
    target->typeAttributes = typeAttributes;
    target->offsetHigh = (offset >> 16) & 0xFFFF;
}