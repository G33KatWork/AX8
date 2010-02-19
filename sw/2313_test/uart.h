#ifndef __UART_H_
#define __UART_H_

void uart_init(void);
void uart_putc(char c);
void uart_puts(const char *s);
void uart_puts_P(PGM_P s);

#endif

