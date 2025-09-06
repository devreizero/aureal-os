#ifndef IDT_H
#define IDT_H

#include <address.h>
#include <stdint.h>

typedef uint16_t IDTSegmentSelector;
typedef uint8_t IDTTypeAttributes;

/**
 * Interrupt Descriptor Table
 * -------------------------------------------------------------------------
 * Offset  | Length | Description
 * --------|--------|-------------------------------------------------------
 * 0x00    | 16     | Offset Low
 * 0x10    | 16     | Segment Selector
 * 0x20    | 3      | Interrupt Stack Table (IST)   NOTE: 64-bits IDT only
 * 0x23    | 5      | Reserved
 * 0x28    | 4      | Gate type
 * 0x2C    | 1      | Zero, always ZERO, set it to ZERO!
 * 0x2D    | 2      | Privilege level (ring)
 * 0x2F    | 1      | Present bit                   NOTE: Must set to 1 for entry to be valid
 * 0x30    | 16     | Offset middle                 NOTE: Offset high for 32-bits entries
 * 0x40    | 32     | Offset high                   NOTE: 64-bits IDT only
 * 0x60    | 32     | Reserved                      NOTE: 64-bits IDT only

 *
 * Notes:
 *
 * - Valid gate types for 32-bits IDT entry:
 *     1. 0x6 | 16-bits Interrupt Gate
 *     2. 0x7 | 16-bits Trap Gate
 *     3. 0xE | 32-bits Interrupt Gate
 *     4. 0xF | 32-bits Trap Gate
 *     5. 0x5 | Task Gate. Note that in this case, the offset value is unused and should be set to 0
 *
 * - Valid gate types for 64-bits IDT entry:
 *     1. 0xE | 64-bit Interrupt Gate
 *     2. 0xF | 64-bit Trap Gate
 *
 * - Segment Selectors contains:
 *     1. 2 bits Requested Privilege Level (RPL)
 *     2. 1 bit TI - set to 0 for GDT, 1 for LDT
 *     3. 13 bits index pointing to either GDT or LDT
 *
 * - Gate Type, Zero, Privilege Level, and Present Bit is part of typeAttributes
 */

struct IDTEntry {
    Offset16 offsetLow : 16;
    IDTSegmentSelector segmentSelector : 16; 
    Offset8 interruptStackTable : 3;        // 64-bits IDT only
    Reserved8 reserved : 5;
    IDTTypeAttributes typeAttributes : 8;
    Offset16 offsetHigh : 16;
    #ifdef BUILD_64BITS
    Offset32 offset64 : 32;                 // 64-bits IDT only
    Reserved32 reserved2 : 32;              // 64-bits IDT only
    #endif
} __attribute__((packed));

struct IDTDescriptor {
    Limit16 limit;
    VirtAddr base;
} __attribute__((packed));

// =================== ===================================================================================================
// Function 

void initIDT();
void setIDTEntry32(struct IDTEntry *target, Offset offset, IDTSegmentSelector segmentSelector, IDTTypeAttributes typeAttributes);
void setIDTEntry64(struct IDTEntry *target, Offset offset, IDTSegmentSelector segmentSelector, Offset8 ist, IDTTypeAttributes typeAttributes);

#endif