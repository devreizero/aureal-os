#include <stdint.h>

#include "arch/i386/port.h"
#include "common/serial.h"

#define COM1_BASE_PORT 0x3F8

/**
 * Serial Port Layout Table
 * -----------------
 * Offset  | Length | Description
 * --------|--------|-------------------------------------------------------
 * 0x00    | 1      | Data register (read/write) for the device
 * 0x01    | 1      | Interrupt Enable Register (IER)
 * 0x02    | 1      | Interrupt Identification / FIFO Control Register (IIR/FCR)
 * 0x03    | 1      | Line Control Register (LCR)
 * 0x04    | 1      | Modem Control Register (MCR)
 * 0x05    | 1      | Line Status Register (LSR)
 * 0x06    | 1      | Modem Status Register (MSR)
 * 0x07    | 1      | Scratch Register (SCR)
 *
 * Notes:
 * - Length is in bytes; most registers are 1 byte.
 * - Some offsets are read-only or write-only depending on the register.
 * - This layout corresponds to the standard 16550 UART serial port.
 */

void initSerial(uint16_t baudDivisor) {
    // Disable UART interrupts during initialization to prevent unexpected behavior.
    outb(COM1_BASE_PORT + 1, 0x00);                 // Disable all interrupts

    // Set baud rate by enabling Divisor Latch Access Bit (DLAB) in LCR (COM1_BASE_PORT + 3)
    // This gives access to Divisor Latch Low (DLL) and High (DLM) registers
    // Divisor = UART_CLOCK / baud_rate (UART_CLOCK typically 115200 Hz)
    // Example: for 9600 baud, divisor = 115200 / 9600 = 12
    outb(COM1_BASE_PORT + 3, 0x80);                                     // Enable DLAB
    outb(COM1_BASE_PORT + 0, (uint8_t)(baudDivisor & 0xFF));            // DLL low byte
    outb(COM1_BASE_PORT + 1, (uint8_t)((baudDivisor >> 8) & 0xFF));     // DLM high byte

    // Disable DLAB and configure 8 data bits, no parity, 1 stop bit.
    outb(COM1_BASE_PORT + 3, 0x03);

    // Configure FIFO: enable, clear, and set 14-byte threshold.
    // Enabling and clearing them with a threshold can improve performance.
    outb(COM1_BASE_PORT + 2, 0xC7);

    // Configure Modem Control: set RTS/DTR and enable UART interrupts.
    outb(COM1_BASE_PORT + 4, 0x0B);
}

void serialLogz(const volatile char *string) {
    const char *s = (const char *) string - 1;
    while (*++s) {
        serialLogChar(*s);
    }
}

// We used uint16_t because we know that it covers all string length already.
// So using bigger size is unnecessary.
void serialLogn(const volatile char *string, uint16_t length) {
    // Log even past null bytes, we must believe in `length`.
    for (uint16_t i = 0; i < length; i++) {
        serialLogChar(string[i]);
    }
}

void serialLogChar(char c) {
    // Wait until the Transmitter Holding Register (THR) is empty (THRE bit in LSR).
    while (!((inb(COM1_BASE_PORT + 5)) & 0x20));
    outb(COM1_BASE_PORT, c); // Write the character to the Data Register (COM1_BASE_PORT).
}