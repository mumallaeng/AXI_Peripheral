#include "StopWatch.h"

stopWatch_e stopWatchState;
static uint32_t counter;

void StopWatch_Init()
{
    LED_Init();
    FND_Init();
    Button_Init();

    stopWatchState = STOP;
    counter = 0;
}

void StopWatch_Execute()
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
        else if (Button_GetState(&hbtnClear) == ACT_PUSHED)
        {
            stopWatchState = CLEAR;
        }
        break;
    case CLEAR:
        counter = 0;
        FND_SetNum(counter);
        stopWatchState = STOP;
        break;
    default:
        stopWatchState = STOP;
        break;
    }
}

void StopWatch_RunTime()
{
    static uint32_t prevTime = 0;
    uint32_t curTime = millis();

    if (curTime - prevTime < 100)
        return;
    prevTime = curTime;

    if (stopWatchState == RUN)
    {
        counter = (counter + 1) % 10000;
        FND_SetNum(counter);
    }
}
