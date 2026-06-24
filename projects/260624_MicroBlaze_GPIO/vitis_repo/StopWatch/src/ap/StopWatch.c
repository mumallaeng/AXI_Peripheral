#include "StopWatch.h"

stopWatch_e stopWatchState;

void StopWatch_Init()
{
    LED_Init();
    FND_Init();
    Button_Init();

    stopWatchState = STOP;
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
    uint32_t curTime = getTick();

    if (curTime - prevTime >= 1000)
    {
        prevTime = curTime;
        FND_IncNum();
    }
}