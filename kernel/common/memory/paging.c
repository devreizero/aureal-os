#include <address.h>

#include "common/memory/paging.h"
#include "common/memory/pmmgr.h"

static struct PageTable *pageTable;

static inline void flushTLB(VirtAddr page) {
	__asm__ volatile ("invlpg (%0)" :: "r" (page) : "memory");
}

static inline struct PageTable* physToPtr(PhysAddr addr) {
    return (struct PageTable*) ((uintptr_t) addr << 12);
}

static void setPageTableEntry(struct PageEntry* entry, uint8_t flags, PhysAddr physical_address, uint16_t available) {
    entry->present = (flags >> 1) & 1;
    entry->writable = (flags >> 2) & 1;
    entry->userAccessible = (flags >> 3) & 1;
    entry->writeThroughCaching = (flags & 0x8) & 1;
    entry->disableCache = (flags & 0x10) & 1;
    entry->pat = (flags & 0x20) & 1;
    entry->global = (flags & 0x40) & 1;
    entry->avl1 = available & 0x3;
    entry->physicalAddress = physical_address; 
    entry->avl2 = available >> 3;
    entry->noExecute = flags >> 7;
}

static void allocateEntry(struct PageTable *table, Index index, uint8_t flags) {
    void *physicalAddress = kmalloc(4096);
    setPageTableEntry((table->entries + index), flags, (PhysAddr) physicalAddress >> 12, 0);
}

uint64_t readCR3() {
    uint64_t cr3;
    __asm__ volatile ("mov %%cr3, %0" : "=r"(cr3));
    return cr3;
}

// This function initialize Page Table Level-4
struct PageTable *initPageTable() {
    uint64_t cr3 = readCR3();
    pageTable = physToPtr(cr3 >> 12);

    return pageTable;
}

PhysAddr getPhysicalAddress(VirtAddr address) {
    Offset offset = address & 0xFFF;
    Index pageTableIndex = (address >> 12) & 0x1FF;
    Index pageDirectoryIndex = (address >> 21) & 0x1FF;
    Index pageDirectoryPointerIndex = (address >> 30) & 0x1FF;
    Index pageMapLevel4Index = (address >> 39) & 0x1FF;

    struct PageTable *pageDirectoryPointer = physToPtr(pageTable->entries[pageMapLevel4Index].physicalAddress);
    struct PageTable *pageDirectory = physToPtr(pageDirectoryPointer->entries[pageDirectoryPointerIndex].physicalAddress);
    struct PageTable *localPageTable = physToPtr(pageDirectory->entries[pageDirectoryIndex].physicalAddress);

    return (PhysAddr) ((localPageTable->entries[pageTableIndex].physicalAddress << 12) + offset);
}

void mapPage(VirtAddr virtualAddress, PhysAddr physicalAddress, uint8_t flags) {
    Index pageTableIndex = (virtualAddress >> 12) & 0x1FF;
    Index pageDirectoryIndex = (virtualAddress >> 21) & 0x1FF;
    Index pageDirectoryPointerIndex = (virtualAddress >> 30) & 0x1FF;
    Index pageMapLevel4Index = (virtualAddress >> 39) & 0x1FF;
 
    if (!pageTable->entries[pageMapLevel4Index].present)
        allocateEntry(pageTable, pageMapLevel4Index, flags);

    struct PageTable *pageDirectoryPointer = physToPtr(pageTable->entries[pageMapLevel4Index].physicalAddress);
    struct PageTable *pageDirectory = physToPtr(pageDirectoryPointer->entries[pageDirectoryPointerIndex].physicalAddress);
    struct PageTable *localPageTable = physToPtr(pageDirectory->entries[pageDirectoryIndex].physicalAddress);

    if (!pageDirectoryPointer->entries[pageDirectoryPointerIndex].present) 
        allocateEntry(pageDirectoryPointer, pageDirectoryPointerIndex, flags);

    if (!pageDirectory->entries[pageDirectoryIndex].present) 
        allocateEntry(pageDirectory, pageDirectoryIndex, flags);

    setPageTableEntry((localPageTable->entries + pageTableIndex), flags, physicalAddress >> 12, 0);
	
    // Now you need to flush the entry in the TLB
    flushTLB(virtualAddress);
}