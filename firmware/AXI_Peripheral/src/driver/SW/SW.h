/*
 * SW.h
 *
 *  Created on: 2026. 6. 27.
 *      Author: kccistc
 */
#ifndef SRC_DRIVER_SW_SW_H_
#define SRC_DRIVER_SW_SW_H_

#include "../../HAL/GPIO/GPIO.h"
#include <stdint.h>

typedef struct {
    GPIO_TypeDef *GPIOx;
    uint32_t      gpio_pin;
} hswitch;

extern hswitch hsw[16];

void    SW_Init(void);
uint8_t SW_GetState(hswitch *hsw);   // 스위치 1개
uint8_t SW_GetPort(void);            // 하위 8개 한번에
uint8_t SW_GetPortHigh(void);        // 상위 8개 한번에
#endif /* SRC_DRIVER_SW_SW_H_ */
