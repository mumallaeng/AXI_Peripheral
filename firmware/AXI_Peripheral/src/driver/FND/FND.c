/*
 * FND.c
 *
 *  Created on: 2026. 6. 24.
 *      Author: kccistc
 */
#include "FND.h"

#define FND_DATA_GPIO GPIOA
#define FND_COM_GPIO  GPIOB

#define FND_DIGIT_0   0
#define FND_DIGIT_1   1
#define FND_DIGIT_2   2
#define FND_DIGIT_3   3

uint32_t fndNumber  = 0;
uint32_t fndDPData  = 0;
uint8_t  fndData    = 0;
uint8_t  fndHexMode = 0;   // 0: 10진수(스톱워치), 1: hex(SPI read)

uint8_t hour_10, hour_1;
uint8_t min_10,  min_1;
uint8_t sec_10,  sec_1;
uint8_t msec_10, msec_1;

void FND_Init()
{
    uint32_t fndComTemp = GPIO_GetCR(FND_COM_GPIO);
    GPIO_SetMode(FND_DATA_GPIO, 0xff);
    fndComTemp |= 0x0f;
    GPIO_SetMode(FND_COM_GPIO, fndComTemp);
}

void FND_SetNum(uint32_t num)
{
    fndHexMode = 0;
    fndNumber  = num;
}

void FND_SetHex(uint32_t num)
{
    fndHexMode = 1;
    fndNumber  = num;
}

void FND_SetTime(uint8_t mode, uint32_t hour, uint32_t min, uint32_t sec, uint32_t msec)
{
    hour_1  = hour      % 10;
    hour_10 = hour / 10 % 10;
    min_1   = min       % 10;
    min_10  = min  / 10 % 10;
    sec_1   = sec       % 10;
    sec_10  = sec  / 10 % 10;
    msec_1  = msec      % 10;
    msec_10 = msec / 10 % 10;

    if(mode == 0)
        fndNumber = (min_1 * 1000) + (sec_10 * 100) + (sec_1 * 10) + msec_10;
    else
        fndNumber = (hour_10 * 1000) + (hour_1 * 100) + (min_10 * 10) + min_1;

    fndHexMode = 0;
}

void FND_Excute()
{
    if(fndHexMode)
        FND_DispHex(fndNumber);
    else
        FND_DispNum(fndNumber);
}

void FND_SelDigit(uint32_t digit)
{
    uint32_t digitPos;
    digitPos = GPIO_GetODR(FND_COM_GPIO);
    digitPos = (digitPos | 0x0f) & ~(1 << digit);
    GPIO_WritePort(FND_COM_GPIO, digitPos);
}

void FND_SetDP(uint32_t fndDigitSel, uint32_t fndDpState)
{
    if(fndDpState == FND_DP_ON)
        fndDPData |=  (1 << fndDigitSel);
    else
        fndDPData &= ~(1 << fndDigitSel);
}

void FND_DispDigit(uint32_t num, uint32_t fndDP)
{
    uint8_t fndFont[16] = {
        0xc0,  // 0
        0xf9,  // 1
        0xa4,  // 2
        0xb0,  // 3
        0x99,  // 4
        0x92,  // 5
        0x82,  // 6
        0xf8,  // 7
        0x80,  // 8
        0x90,  // 9
        0x88,  // A
        0x83,  // b
        0xc6,  // C
        0xa1,  // d
        0x86,  // E
        0x8e,  // F
    };

    if(fndDP)
        fndData = fndFont[num & 0xF] & ~(0x80);  // dp on
    else
        fndData = fndFont[num & 0xF] |  (0x80);  // dp off

    GPIO_WritePort(FND_DATA_GPIO, fndData);
}

void FND_DispAllOff()
{
    uint32_t digitPos;
    digitPos = GPIO_GetODR(FND_COM_GPIO);
    digitPos = digitPos | 0x0f;
    GPIO_WritePort(FND_COM_GPIO, digitPos);
}

void FND_DispNum(uint32_t num)
{
    static uint32_t fndDigitState = 0;
    fndDigitState = (fndDigitState + 1) % 4;
    FND_DispAllOff();
    switch(fndDigitState)
    {
    case 0: FND_DispDigit(num        % 10, fndDPData & 0x01); FND_SelDigit(FND_DIGIT_0); break;
    case 1: FND_DispDigit(num / 10   % 10, fndDPData & 0x02); FND_SelDigit(FND_DIGIT_1); break;
    case 2: FND_DispDigit(num / 100  % 10, fndDPData & 0x04); FND_SelDigit(FND_DIGIT_2); break;
    case 3: FND_DispDigit(num / 1000 % 10, fndDPData & 0x08); FND_SelDigit(FND_DIGIT_3); break;
    }
}

void FND_DispHex(uint32_t num)
{
    static uint32_t fndDigitState = 0;
    fndDigitState = (fndDigitState + 1) % 4;
    FND_DispAllOff();
    switch(fndDigitState)
    {
    case 0: FND_DispDigit((num >>  0) & 0xF, fndDPData & 0x01); FND_SelDigit(FND_DIGIT_0); break;
    case 1: FND_DispDigit((num >>  4) & 0xF, fndDPData & 0x02); FND_SelDigit(FND_DIGIT_1); break;
    case 2: FND_DispDigit((num >>  8) & 0xF, fndDPData & 0x04); FND_SelDigit(FND_DIGIT_2); break;
    case 3: FND_DispDigit((num >> 12) & 0xF, fndDPData & 0x08); FND_SelDigit(FND_DIGIT_3); break;
    }
}
