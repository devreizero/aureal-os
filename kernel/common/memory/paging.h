#ifndef PAGING_H
#define PAGING_H

#include <address.h>
#include <stdint.h>

// This TLBCacheRecord isn't used in the code, it really is just here for reference on how
// the TLB structure its data and also how it works.
// The TLB is a cache within the CPU that stores recent virtual-to-physical address translations.
// When the CPU needs to translate an address, it first checks the TLB. 
// The rest is just hit or miss like a normal cache.
// 
// TLB stands for Translation Lookaside Buffer.
struct TLBCacheRecord {
    VirtAddr entryVirtualAddress;
    PhysAddr relevantPhysicalAddress;
    uint16_t permissions;
} __attribute__((unused));

struct PageEntry {
    uint8_t present : 1;                    // 1 bit     P ▪ Present Bit, always 1.
    uint8_t writable : 1;                   // 1 bit   R/W ▪ Set to 0 if this page is read-only, otherwise set to 1 for read-write.
    uint8_t userAccessible : 1;             // 1 bit   U/S ▪ Whether this page is user space accessible or not.
    uint8_t writeThroughCaching : 1;        // 1 bit   PWT ▪ Set to 0 for write-back (write to cache first), otherwise set to 1 for write-through (skip writing to cache)
    uint8_t disableCache : 1;               // 1 bit   PCD ▪ Set to 0 if cache is enabled, otherwise 1. Hardware access, such as MMIO, typically prefer cache to be disabled.
    uint8_t accessed : 1;                   // 1 bit     A ▪ Set to 1 by the CPU every time PDE or PTE was read during virtual address translation. The CPU doesn't reset this to 0, the OS does.
    uint8_t dirty : 1;                      // 1 bit     D ▪ Determine whether a page has been written to. CPU sets this.
    uint8_t pat : 1;                        // 1 bit   PAT ▪ ----- Page Attribute Table bit. Add explanation later.
    uint8_t global : 1;                     // 1 bit     G ▪ Set to 1 for this page to be not flushed on CR3 reload, as long as CR4.PGE = 1. Don't use this for user space page because
                                            //               they’re process-specific. Otherwise, one process could accidentally access another’s memory through stale TLB entries (bad!).
    uint8_t avl1 : 3;                       // 3 bits  AVL ▪ Available for OS's uses
    uintptr_t physicalAddress : 40;         // 40 bits     ▪ The actual physical address
    uint16_t avl2 : 11;                     // 11 bits     ▪ Available for OS's uses
    uint8_t noExecute : 1;                  // 1 bit    NX ▪ Wheter the memory in this page is executable or not.
};

struct PageTable {
    struct PageEntry entries[512];
};

uint64_t cr3Read();
struct PageTable *pageTableInit();
PhysAddr getPhysicalAddress(VirtAddr address);
void mapPage(VirtAddr virtualAddress, PhysAddr physicalAddress, uint8_t flags);

#endif