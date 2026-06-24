#include "StopWatch.h"
#include "../driver/LED/LED.h"

#define STOP_STATE_LED 5
#define RUN_STATE_LED 7

stopWatch_e stopWatchState;
uint32_t stopWatchLED;
uint32_t stopWatchStateLED;
uint32_t counter;

void StopWatch_Init()
{
    LED_Init();
    FND_Init();
    Button_Init();

    stopWatchState = STOP;
    counter = 0;
    stopWatchLED = 0x01;
    stopWatchStateLED = 0;
}

void StopWatch_Execute()
{
    StopWatch_RunTime();
    StopWatch_ControlState();
    FND_SetNum(counter);
    StopWatch_ControlLED();
}

void StopWatch_ControlState()
{
    switch (stopWatchState)
    {
    case STOP:
        if (Button_GetState(&hbtnRunStop) == ACT_PUSHED)
        {
            stopWatchState = RUN;
        }
        else if (Button_GetState(&hbtnClear) == ACT_PUSHED)
        {
            stopWatchState = CLEAR;
        }
        break;
    case RUN:
        if (Button_GetState(&hbtnRunStop) == ACT_PUSHED)
        {
            stopWatchState = STOP;
        }
        break;
    case CLEAR:
        stopWatchState = STOP;
        counter = 0;
        break;
    default:
        stopWatchState = STOP;
        break;
    }
}

void StopWatch_RunTime()
{
    static uint32_t prevTime = 0;
    // static uint8_t ledstate = 1;
    uint32_t curTime = millis();

    if (curTime - prevTime < 100)
        return;
    prevTime = curTime;

    if (stopWatchState == RUN)
    {
        counter++;
        // ledstate = (ledstate<<1)|(ledstate>>7);
        // LED_WritePort8(LED_LOW_GPIO, ledstate);
    }
}

void StopWatch_ControlLED()
{

    switch (stopWatchState)
    {
    case STOP:
        StopWatch_StopLED();
        break;

    case RUN:
        StopWatch_RunLED();
        break;

    case CLEAR:
        StopWatch_ClearLED();
        break;
    }
}

void StopWatch_RunLED()
{
    static uint32_t prevTime = 0;
    uint32_t curTime = millis();

    stopWatchStateLED &= ~(1 << STOP_STATE_LED);
    stopWatchStateLED |= (1 << RUN_STATE_LED);
    LED_WritePort8(LED_HI_GPIO, stopWatchStateLED);

    if (curTime - prevTime < 100)
        return;
    prevTime = curTime;

    stopWatchLED = (stopWatchLED << 1) | (stopWatchLED >> 7);
    LED_WritePort8(LED_LOW_GPIO, stopWatchLED);
}

void StopWatch_StopLED()
{
    stopWatchStateLED |= (1 << STOP_STATE_LED);
    stopWatchStateLED &= ~(1 << RUN_STATE_LED);
    LED_WritePort8(LED_HI_GPIO, stopWatchStateLED);
}

void StopWatch_ClearLED()
{
    stopWatchLED = 0x01;
    LED_WritePort8(LED_LOW_GPIO, stopWatchLED);
}
