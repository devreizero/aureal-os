#include "boot_protocol/limine/boot/memory.h"
#include "boot_protocol/limine/request.h"
#include "common/kernel.h"
#include "common/memory/pmmgr.h"
#include <stddef.h>
#include <stdint.h>

#define KERNEL_BASE 0xFFFFFFFF80000000

extern char _kernel_end;

void initMemory() {
    static struct pmmgrEntry entry0 = {0};
    pmmgrEntries = &entry0;
    pmmgrEntryCount = 1;
    
    // ------------------------
    
    uintptr_t entryCount = 0;
    struct limine_memmap_response *res = memmapRequest.response;
    struct limine_memmap_entry *entry = NULL;

    for (size_t i = 0; i < res->entry_count; i++) {
        entry = res->entries[i];
        switch (entry->type) {
            case LIMINE_MEMMAP_USABLE: {
                if (entryCount == 0 || entry->length > entry0.size) {
                    entry0.base = entry->base;
                    entry0.size = entry->length;
                    entry0.type = MEM_USABLE;
                }
            }
            case LIMINE_MEMMAP_BOOTLOADER_RECLAIMABLE:
            case LIMINE_MEMMAP_ACPI_RECLAIMABLE:
            case LIMINE_MEMMAP_ACPI_NVS:
            case LIMINE_MEMMAP_RESERVED:
            case LIMINE_MEMMAP_BAD_MEMORY:
                entryCount++;
        }
    }

    kmemInit(&_kernel_end, entry0.size);
    if (sizeof(struct pmmgrEntry) * entryCount + sizeof(struct kmemBlock) > entry0.size) {
        STATUS_FLAGS |= STATUS_ERR;
        return;
    }

    struct pmmgrEntry *entries = kmalloc(sizeof(struct pmmgrEntry) * entryCount); // Guarantee non-null value
    for (size_t i = 0, j = 0; j < entryCount; i++) {
        entry = res->entries[i];
        
        if (entry->type == LIMINE_MEMMAP_FRAMEBUFFER) continue;
        entries[j].base = entry->base;
        entries[j].size = entry->length;

        switch (entry->type) {
            case LIMINE_MEMMAP_BOOTLOADER_RECLAIMABLE:
            case LIMINE_MEMMAP_USABLE:                   entries[j].type = MEM_USABLE; break;
            case LIMINE_MEMMAP_ACPI_RECLAIMABLE:         entries[j].type = MEM_ACPI_RECLAIM; break;
            case LIMINE_MEMMAP_ACPI_NVS:                 entries[j].type = MEM_ACPI_NVS; break;
            case LIMINE_MEMMAP_BAD_MEMORY:               entries[j].type = MEM_BADRAM; break;
            case LIMINE_MEMMAP_RESERVED:                 entries[j].type = MEM_RESERVED; break;
        }

        j++;
    }

    pmmgrEntries = entries;
    pmmgrEntryCount = entryCount;

    STATUS_FLAGS |= STATUS_MEMOK;
}