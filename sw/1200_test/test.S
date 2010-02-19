#include <avr/io.h>

intsav  =   0
work    =   16
leds    =   17
count   =   18
state   =   19

#define LEFT    1
#define RIGHT   2

.section .text

.global main
main:
    rcall   ioinit
    ldi     leds, 1
    ldi     state, LEFT
    sei
1:  rjmp    1b


ioinit:
    ldi     work, 0xFF
    out     _SFR_IO_ADDR(DDRB), work        ;all LEDs output

    ldi     work, _BV(CS00) | _BV(CS02)     ;prescaler 1024
    out     _SFR_IO_ADDR(TCCR0), work

    ldi     work, _BV(TOIE0)                ;enable overflow interrupt
    out     _SFR_IO_ADDR(TIMSK), work

    ret


.global TIMER0_OVF_vect
TIMER0_OVF_vect:
    in      intsav, _SFR_IO_ADDR(SREG)

    cpi     count, 21                       ;125ms
    breq    reset

    inc     count
    rjmp    out

reset:
    ldi     count, 0
    
    cpi     leds, 1                         ;led on right side?
    breq    setleft                         ;we need to go left
    rjmp    checkleft                       ;led on left side?

setleft:
    ldi     state, LEFT
    rjmp    shiftLeds

checkleft:
    cpi     leds, 128                       ;led on left side?
    breq    setright                        ;we need to go right
    rjmp    shiftLeds

setright:
    ldi     state, RIGHT


shiftLeds:
    cpi     state, LEFT                     ;are we going left?
    breq    doLeft                          ;shift bit left
    lsr     leds                            ;else shift right
    rjmp    done

doLeft:
    lsl     leds

done:
    out     _SFR_IO_ADDR(PORTB), leds

out:
    out     _SFR_IO_ADDR(SREG), intsav    
    reti


.global __vector_default
__vector_default:
    reti

.end

