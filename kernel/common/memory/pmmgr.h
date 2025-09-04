#ifndef PMMGR_H
#define PMMGR_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

enum pmmgrMemoryType {
    MEM_USABLE,
    MEM_RESERVED,
    MEM_ACPI_RECLAIM,
    MEM_ACPI_NVS,
    MEM_BADRAM,
    MEM_MMIO
};

struct kmemBlock {
    size_t size;              // Size of this block
    bool isFree;              // Free or used
    struct kmemBlock *next;   // Next block
};

struct pmmgrEntry {
    uintptr_t base;
    uintptr_t size;
    enum pmmgrMemoryType type;
};

extern struct pmmgrEntry *pmmgrEntries;
extern size_t pmmgrEntryCount;

void kmemInit(void *heapBase, size_t heapSize);
void *kmalloc(size_t size);
void *krealloc(void *ptr, size_t newSize);
void kfree(void *ptr);

#endif