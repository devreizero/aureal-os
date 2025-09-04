#include "common/memory/pmmgr.h"

#include <memory.h>

// ==============================================================================================================================================
// This is a simple implementation of a free list allocator.

// Alignment to 16 bytes for safety
#define ALIGN16(x) (((x) + 15) & ~15)

static struct kmemBlock *heapStart = NULL;
static struct kmemBlock *heapEnd = NULL;

// Initialize heap with a pre-allocated memory region
void kmemInit(void *heapBase, size_t heapSize) {
    heapStart = (struct kmemBlock *)heapBase;
    heapStart->size = heapSize - sizeof(struct kmemBlock);
    heapStart->isFree = true;
    heapStart->next = NULL;
    heapEnd = heapStart;
}

void *kmalloc(size_t size) {
    size = ALIGN16(size);
    struct kmemBlock *curr = heapStart;

    while (curr) {
        if (curr->isFree && curr->size >= size) {
            // Split if block is larger than needed
            if (curr->size > size + sizeof(struct kmemBlock)) {
                struct kmemBlock *newBlock = (struct kmemBlock *)((uint8_t *)curr + sizeof(struct kmemBlock) + size);
                newBlock->size = curr->size - size - sizeof(struct kmemBlock);
                newBlock->isFree = true;
                newBlock->next = curr->next;
                curr->next = newBlock;
                curr->size = size;
            }
            curr->isFree = false;
            return (uint8_t *)curr + sizeof(struct kmemBlock);
        }
        curr = curr->next;
    }
    return NULL; // Out of memory
}

void kfree(void *ptr) {
    if (!ptr) return;

    struct kmemBlock *block = (struct kmemBlock *)((uint8_t *)ptr - sizeof(struct kmemBlock));
    block->isFree = true;

    // Coalesce adjacent free blocks
    struct kmemBlock *curr = heapStart;
    while (curr && curr->next) {
        if (curr->isFree && curr->next->isFree) {
            curr->size += sizeof(struct kmemBlock) + curr->next->size;
            curr->next = curr->next->next;
        } else {
            curr = curr->next;
        }
    }
}

void *krealloc(void *ptr, size_t newSize) {
    if (!ptr) return kmalloc(newSize);
    if (newSize == 0) { kfree(ptr); return NULL; }

    struct kmemBlock *block = (struct kmemBlock *)((uint8_t *)ptr - sizeof(struct kmemBlock));
    if (block->size >= newSize) return ptr; // Fits in place

    void *newPtr = kmalloc(newSize);
    if (newPtr) {
        memcpy(newPtr, ptr, block->size);
        kfree(ptr);
    }
    return newPtr;
}