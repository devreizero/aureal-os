#ifndef ADDRESS_H
#define ADDRESS_H

#include <stdint.h>
#include <stddef.h>

typedef uintptr_t Address;
typedef uintptr_t VirtAddr;
typedef uintptr_t PhysAddr;

typedef uintptr_t Offset;
typedef uint64_t Offset64;
typedef uint32_t Offset32;
typedef uint16_t Offset16;
typedef uint8_t Offset8;

typedef size_t Index;
typedef uint64_t Index64;
typedef uint32_t Index32;
typedef uint16_t Index16;
typedef uint8_t Index8;

typedef size_t Limit;
typedef uint64_t Limit64;
typedef uint32_t Limit32;
typedef uint16_t Limit16;
typedef uint8_t Limit8;

typedef uint64_t Reserved64;
typedef uint32_t Reserved32;
typedef uint16_t Reserved16;
typedef uint8_t Reserved8;

#endif