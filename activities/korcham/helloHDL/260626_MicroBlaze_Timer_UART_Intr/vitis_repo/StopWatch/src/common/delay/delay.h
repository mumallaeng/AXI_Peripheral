/*
 * delay.h
 *
 *  Created on: 2026. 6. 24.
 *      Author: kccistc
 */

#ifndef SRC_COMMON_DELAY_DELAY_H_
#define SRC_COMMON_DELAY_DELAY_H_

#include "sleep.h"

void delay_sec(uint32_t seconds);
void delay_ms(uint32_t msec);
void delay_us(ULONG useconds);
uint32_t millis();
void incTick();


#endif /* SRC_COMMON_DELAY_DELAY_H_ */
