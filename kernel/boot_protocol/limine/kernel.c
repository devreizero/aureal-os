#include <stddef.h>
#include <stdbool.h>
#include <limine.h>

#include "boot_protocol/limine/boot/memory.h"
#include "common/kernel.h"
#include "common/memory/pmmgr.h"

extern uint64_t limine_base_revision[3];  //   LIMINE_BASE_REVISION

uint16_t STATUS_FLAGS = 0;
struct pmmgrEntry *pmmgrEntries = {0};
size_t pmmgrEntryCount = 0;

void kmain(void) {
    if (LIMINE_BASE_REVISION_SUPPORTED == false) {
        hang();
    }

    initMemory();
    
    hang();
}

void hang(void) {
    for (;;) {
        __asm__ ("hlt");
    }
}