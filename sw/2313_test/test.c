#include <avr/io.h>
#include <util/delay.h>
#include <avr/pgmspace.h>
#include "uart.h"

int main(void)
{
	uart_init();
	while(1)
	{
		uart_puts_P(PSTR("Hello, World!\n"));
		_delay_ms(1000);
	}

	return 0;
}
