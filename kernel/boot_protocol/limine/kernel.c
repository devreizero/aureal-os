#include <stddef.h>
#include <stdbool.h>
#include <limine.h>

#include "boot_protocol/limine/boot/memory.h"
#include "common/interrupt/idt.h"
#include "common/kernel.h"
#include "common/memory/paging.h"
#include "common/memory/pmmgr.h"
#include "common/serial.h"

extern uint64_t limine_base_revision[3];  //   LIMINE_BASE_REVISION

uint16_t STATUS_FLAGS = 0;
struct pmmgrEntry *pmmgrEntries = {0};
size_t pmmgrEntryCount = 0;

void kmain(void) {
    if (LIMINE_BASE_REVISION_SUPPORTED == false) {
        hang();
    }

    if(archOnBeforeInit) archOnBeforeInit();

    serialLogz("Hi, we're now doing initial setup.\r\n");
    serialLogz("Device is "
    #ifdef BUILD_64BITS
    "64-bits"
    #else
    "32-bits"
    #endif
    "\r\n"
    );

    initIDT();
    initPageTable();
    initMemory();

    serialLogz("Initial setup completed.\r\n");
    
    hang();
}

void hang(void) {
    for (;;) {
        __asm__ ("hlt");
    }
}