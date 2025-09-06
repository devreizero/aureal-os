#ifndef ISR_H
#define ISR_H

#include <stdint.h>

#if defined(BUILD_X64)

struct InterruptFrame {
    // General-purpose registers pushed by our ISR stub
    uint64_t r11, r10, r9, r8;
    uint64_t rsi, rdi, rdx, rcx, rax;

    // Interrupt number and error code (pushed manually or by CPU)
    uint64_t intNo, errCode;

    // CPU-pushed state on interrupt/trap
    uint64_t rsp, rflags, cs, rip;
} __attribute__((packed));

#elif defined(BUILD_I386)

struct InterruptFrame {
    // General-purpose registers pushed by our ISR stub
    uint32_t esi, edi, ebp, esp_dummy, ebx, edx, ecx, eax;

    // Interrupt number and error code (pushed manually or by CPU)
    uint32_t intNo, errCode;

    // CPU-pushed state on interrupt/trap
    uint32_t eip, cs, eflags, useresp, ss;
} __attribute__((packed));

#else

#error "Failed to build: Unkown architecture. Only x86 and x64 are currently supported."

#endif

void exceptionHandler(struct InterruptFrame *frame);
void irqHandler(struct InterruptFrame *frame); 
void registerInterruptHandler(uint8_t irq, void (*handler)(struct InterruptFrame *));

#endif