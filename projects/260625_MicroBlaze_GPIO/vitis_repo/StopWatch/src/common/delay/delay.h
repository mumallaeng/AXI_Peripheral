#ifndef SRC_COMMON_DELAY_DELAY_H
#define SRC_COMMON_DELAY_DELAY_H

#include "sleep.h"

uint32_t millis();
void incTick();
void delay_ms(uint32_t ms);
void delay_us(uint32_t us);
void delay_sec(uint32_t sec);

#endif // SRC_COMMON_DELAY_DELAY_H