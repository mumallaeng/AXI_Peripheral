#ifndef SRC_AP_STOPWATCH_H
#define SRC_AP_STOPWATCH_H

#include <stdint.h>

#include "../common/delay/delay.h"
#include "../driver/FND/FND.h"
#include "../driver/LED/LED.h"
#include "../driver/button/button.h"

typedef enum
{
    STOP,
    RUN,
    CLEAR
} stopWatch_e;

void StopWatch_Init();
void StopWatch_Execute();
void StopWatch_ControlState();
void StopWatch_RunTime();
void StopWatch_ControlLED();
void StopWatch_RunLED();
void StopWatch_StopLED();
void StopWatch_ClearLED();

#endif // SRC_AP_STOPWATCH_H
