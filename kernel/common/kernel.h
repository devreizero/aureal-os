#ifndef KERNEL_H
#define KERNEL_H

#include <stdint.h>

void hang();

extern uint16_t STATUS_FLAGS;

#define STATUS_ERR   (1 << 0)
#define STATUS_MEMOK (1 << 1)

// Rest of bits are reserved

#endif