#include <stdint.h>
#include <avr/io.h>
#include <avr/pgmspace.h>
#include "uart.h"

#define BAUD 115200
#define UBRR_VAL ((F_CPU+BAUD*8)/(BAUD*16)-1)

void uart_init(void)
{
    UBRR = UBRR_VAL;
    UCR = _BV(TXEN) | _BV(TXB8);	//enable tx, 8bit
}

void uart_putc(char c)
{
    if (c == '\n')
        uart_putc('\r');
    while (!(USR & _BV(UDRE)));
    UDR = c;
}

void uart_puts(const char *s)
{
    do
    {
        uart_putc (*s);
    }
    while (*s++);
}

void uart_puts_P(PGM_P s)
{
    while (1)
    {
        unsigned char c = pgm_read_byte (s);
        s++;
        if ('\0' == c)
            break;
        uart_putc (c);
    }
}



