#include "button.h"

hbutton hbtnRunStop, hbtnClear;

void Button_Init()
{
    uint32_t btnPort = GPIO_GetCR(GPIOB);
    btnPort &= ~(1 << 4 | 1 << 5);
    GPIO_SetMode(GPIOB, btnPort);
    Button_SetInit(&hbtnRunStop, GPIOB, GPIO_PIN_4);
    Button_SetInit(&hbtnClear, GPIOB, GPIO_PIN_5);
}

void Button_SetInit(hbutton *btn, GPIO_TypeDef *GPIOx, uint32_t gpio_pin)
{
    btn->GPIOx = GPIOx;
    btn->gpio_pin = gpio_pin;
    btn->prevState = RELEASED;
}

button_status_e Button_GetState(hbutton *btn)
{
    // static button_state_e prevState = RELEASED;
    button_state_e curState = GPIO_ReadPin(btn->GPIOx, btn->gpio_pin) ? PUSHED : RELEASED;

    if (curState == PUSHED && btn->prevState == RELEASED)
    {
        btn->prevState = curState;
        delay_ms(5);
        return ACT_PUSHED;
    }
    else if (curState == RELEASED && btn->prevState == PUSHED)
    {
        btn->prevState = curState;
        delay_ms(5);
        return ACT_RELEASED;
    }
    else
    {
        return NO_ACT;
    }
}
