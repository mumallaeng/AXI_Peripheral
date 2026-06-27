/*
 * SW.c
 *
 *  Created on: 2026. 6. 27.
 *      Author: kccistc
 */
#include "SW.h"

hswitch hsw[16];

void SW_SetInit(hswitch *hsw, GPIO_TypeDef *GPIOx, uint32_t gpio_pin)
{
    hsw->GPIOx    = GPIOx;
    hsw->gpio_pin = gpio_pin;
}

void SW_Init(void)
{
    GPIO_SetMode(GPIOE, GPIO_INPUT);  // SW 0~7 → GPIOE 입력 설정
    GPIO_SetMode(GPIOF, GPIO_INPUT);  // SW8~15
    // SW0~7 → GPIOE
    SW_SetInit(&hsw[0], GPIOE, GPIO_PIN_0);
    SW_SetInit(&hsw[1], GPIOE, GPIO_PIN_1);
    SW_SetInit(&hsw[2], GPIOE, GPIO_PIN_2);
    SW_SetInit(&hsw[3], GPIOE, GPIO_PIN_3);
    SW_SetInit(&hsw[4], GPIOE, GPIO_PIN_4);
    SW_SetInit(&hsw[5], GPIOE, GPIO_PIN_5);
    SW_SetInit(&hsw[6], GPIOE, GPIO_PIN_6);
    SW_SetInit(&hsw[7], GPIOE, GPIO_PIN_7);
    // SW8~15 → GPIOF
    SW_SetInit(&hsw[8], GPIOF, GPIO_PIN_0);
    SW_SetInit(&hsw[9], GPIOF, GPIO_PIN_1);
    SW_SetInit(&hsw[10], GPIOF, GPIO_PIN_2);
    SW_SetInit(&hsw[11], GPIOF, GPIO_PIN_3);
    SW_SetInit(&hsw[12], GPIOF, GPIO_PIN_4);
    SW_SetInit(&hsw[13], GPIOF, GPIO_PIN_5);
    SW_SetInit(&hsw[14], GPIOF, GPIO_PIN_6);
    SW_SetInit(&hsw[15], GPIOF, GPIO_PIN_7);

}

uint8_t SW_GetState(hswitch *hsw)
{
    return GPIO_ReadPin(hsw->GPIOx, hsw->gpio_pin) ? 1 : 0;
}

uint8_t SW_GetPort(void)
{
    return (uint8_t)GPIO_ReadPort(GPIOE);
}

uint8_t SW_GetPortHigh(void)
{
    return (uint8_t)GPIO_ReadPort(GPIOF);
}
