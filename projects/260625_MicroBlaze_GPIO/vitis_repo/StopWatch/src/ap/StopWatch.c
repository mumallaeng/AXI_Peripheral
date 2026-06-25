#include "StopWatch.h"
#include "../driver/LED/LED.h"

stopWatch_e stopWatchState;
stopWatch_t stopWatchTimeData;
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
    stopWatchTimeData.hour = 0;
    stopWatchTimeData.min = 0;
    stopWatchTimeData.sec = 0;
    stopWatchTimeData.ms = 0;
}

void StopWatch_Execute()
{
    StopWatch_RunTime();
    StopWatch_ControlState();
    StopWatch_DispWatch();
}

void StopWatch_DispWatch()
{

    if (stopWatchTimeData.ms % 10 < 5)
    {
        FND_SetDP(FND_DIGIT_1, FND_DP_ON);
    }
    else
    {
        FND_SetDP(FND_DIGIT_1, FND_DP_OFF);
    }

    if (stopWatchTimeData.ms < 50)
    {
        FND_SetDP(FND_DIGIT_3, FND_DP_ON);
    }
    else
    {
        FND_SetDP(FND_DIGIT_3, FND_DP_OFF);
    }

    FND_SetNum((stopWatchTimeData.min % 10 * 1000) + (stopWatchTimeData.sec * 10) + (stopWatchTimeData.ms / 10));
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
        StopWatch_ClearTime();
        break;
    default:
        stopWatchState = STOP;
        break;
    }
}

void StopWatch_IncTime()
{
    if (stopWatchTimeData.ms == 99)
    {
        stopWatchTimeData.ms = 0;
    }
    else
    {
        stopWatchTimeData.ms++;
        return;
    }

    if (stopWatchTimeData.sec == 59)
    {
        stopWatchTimeData.sec = 0;
    }
    else
    {
        stopWatchTimeData.sec++;
        return;
    }

    if (stopWatchTimeData.min == 59)
    {
        stopWatchTimeData.min = 0;
    }
    else
    {
        stopWatchTimeData.min++;
        return;
    }

    if (stopWatchTimeData.hour == 23)
    {
        stopWatchTimeData.hour = 0;
    }
    else
    {
        stopWatchTimeData.hour++;
        return;
    }
}

void StopWatch_RunTime()
{
    static uint32_t prevTime = 0;
    // static uint8_t ledstate = 1;
    uint32_t curTime = millis();

    if (curTime - prevTime < 10)
        return;
    prevTime = curTime;

    if (stopWatchState == RUN)
    {
        counter++;
        StopWatch_IncTime();
    }
}

void StopWatch_ClearTime()
{
    stopWatchTimeData.hour = 0;
    stopWatchTimeData.min = 0;
    stopWatchTimeData.sec = 0;
    stopWatchTimeData.ms = 0;
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
