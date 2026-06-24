#include "FND.h"

uint32_t fndNumber = 0;

void FND_Init()
{
    uint32_t fndComTemp = GPIO_GetCR(FND_COM_GPIO);
    fndComTemp |= 0x0f;
    GPIO_SetMode(FND_COM_GPIO, fndComTemp);
    GPIO_SetMode(FND_DATA_GPIO, 0xff);
}

void FND_SetNum(uint32_t num)
{
    fndNumber = num;
}

void FND_Excute()
{
    FND_DispNum(fndNumber);
}

void FND_SelDigit(uint32_t digit)
{
    uint32_t digitPos;
    digitPos = GPIO_GetODR(FND_COM_GPIO);
    digitPos = (digitPos & 0xf0) & (1 << digit);
    GPIO_WritePort(FND_COM_GPIO, digitPos);
}

void FND_DispDigit(uint32_t num)
{
    uint8_t fndFont[16] = {0xc0, 0xf9, 0xa4, 0xb0, 0x99, 0x92, 0x82, 0xf8,
                           0x80, 0x90, 0x88, 0x83, 0xc6, 0xa1, 0x86, 0x8e};
    GPIO_WritePort(FND_DATA_GPIO, fndFont[num % 10]);
}

void FND_DispAllOff(uint32_t num)
{
    uint32_t digitPos;

    digitPos = GPIO_GetODR(FND_COM_GPIO);
    digitPos |= 0x0f;

    GPIO_WritePort(FND_COM_GPIO, digitPos);
}

void FND_DispNum(uint32_t num)
{
    static uint32_t fndDigitState = 0; // static은 함수가 호출될 때마다 초기화되지 않고, 프로그램이 종료될 때까지 유지되도록함
    fndDigitState = (fndDigitState + 1) % 4;

    switch (fndDigitState)
    {
    case 0:
        FND_SelDigit(FND_DIGIT_0);
        FND_DispDigit(num % 10);
        break;
    case 1:
        FND_SelDigit(FND_DIGIT_1);
        FND_DispDigit((num / 10) % 10);
        break;
    case 2:
        FND_SelDigit(FND_DIGIT_2);
        FND_DispDigit((num / 100) % 10);
        break;
    case 3:
        FND_SelDigit(FND_DIGIT_3);
        FND_DispDigit((num / 1000) % 10);
        break;
    }
}
