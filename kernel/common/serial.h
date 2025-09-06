#ifndef SERIAL_H
#define SERIAL_H

#include <stdint.h>

void initSerial(uint16_t baudDivisor);

void serialLogz(const volatile char *string);

// We used uint16_t because we know that it covers all string length already.
// So using bigger size is unnecesarry.
void serialLogn(const volatile char *string, uint16_t length);

void serialLogChar(char c);

#endif