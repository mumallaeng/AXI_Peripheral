#ifndef SRC_AP_STOPWATCH_H
#define SRC_AP_STOPWATCH_H

#include <stdint.h>

#include "../common/delay/delay.h"
#include "../driver/FND/FND.h"
#include "../driver/LED/LED.h"
#include "../driver/button/button.h"

#define FND_DATA_GPIO GPIOA
#define FND_COM_GPIO GPIOB

#define STOP_STATE_LED 5
#define RUN_STATE_LED 7

#define FND_DIGIT_0 0
#define FND_DIGIT_1 1
#define FND_DIGIT_2 2
#define FND_DIGIT_3 3

typedef enum
{
    STOP,
    RUN,
    CLEAR
} stopWatch_e;

typedef struct
{
    uint8_t hour;
    uint8_t min;
    uint8_t sec;
    uint8_t ms;
} stopWatch_t;

void StopWatch_Init();
void StopWatch_Execute();
void StopWatch_DispWatch();
void StopWatch_ControlState();
void StopWatch_IncTime();
void StopWatch_RunTime();
void StopWatch_ClearTime();
void StopWatch_ControlLED();
void StopWatch_RunLED();
void StopWatch_StopLED();
void StopWatch_ClearLED();

#endif // SRC_AP_STOPWATCH_H
