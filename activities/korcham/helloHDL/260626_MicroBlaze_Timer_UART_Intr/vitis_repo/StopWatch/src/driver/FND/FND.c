/*
 * FND.c
 *
 *  Created on: 2026. 6. 24.
 *      Author: kccistc
 */
#include "FND.h"

#define FND_DATA_GPIO GPIOA
#define FND_COM_GPIO GPIOB

#define FND_DIGIT_0 	0
#define FND_DIGIT_1 	1
#define FND_DIGIT_2 	2
#define FND_DIGIT_3 	3

uint32_t fndNumber = 0;
uint32_t fndDPData = 0;
uint8_t fndData = 0;
uint8_t hour_10, hour_1;
uint8_t min_10, min_1;
uint8_t sec_10, sec_1;
uint8_t msec_10, msec_1;

//static uint32_t fndDigitState = 0;

void FND_Init()
{
	uint32_t fndComTemp = GPIO_GetCR(FND_COM_GPIO);
	GPIO_SetMode(FND_DATA_GPIO, 0xff);
	fndComTemp |= 0x0f;
	GPIO_SetMode(FND_COM_GPIO, fndComTemp);
}

void FND_SetNum(uint32_t num)
{
	fndNumber = num;
}

void FND_SetTime(uint8_t mode, uint32_t hour, uint32_t min, uint32_t sec, uint32_t msec)
{
//	uint32_t value;

		hour_1  = 	hour 		% 10;
		hour_10 = 	hour/10 	% 10;
		min_1  = 	min 		% 10;
		min_10 = 	min/10 		% 10;
		sec_1  = 	sec 		% 10;
		sec_10 = 	sec/10 		% 10;
		msec_1  = 	msec 		% 10;
		msec_10 = 	msec/10 	% 10;

	if(mode == 0){
		fndNumber = (min_1 * 1000) + (sec_10 * 100) + (sec_1 * 10) + msec_10;
//		fndNumber = msec;
	}
	else {
		fndNumber = (hour_10 * 1000) + (hour_1 * 100) + (min_10 * 10) + min_1;
	}

}


void FND_Excute()
{
	FND_DispNum(fndNumber);
}

void FND_SelDigit(uint32_t digit)
{
	uint32_t digitPos;

	digitPos = GPIO_GetODR(FND_COM_GPIO);
	digitPos = (digitPos|0x0f) & ~(1<<digit);

	GPIO_WritePort(FND_COM_GPIO, digitPos);
}



void FND_SetDP(uint32_t fndDigitSel, uint32_t fndDpState)
{
	if(fndDpState == FND_DP_ON){
		fndDPData |= (1<< fndDigitSel);
	}
	else {
		fndDPData &= ~(1<< fndDigitSel);
	}
}

void FND_DispDigit(uint32_t num, uint32_t fndDP)
{
//	uint8_t fndvalue;
	uint8_t fndFont[16]= {0xc0, 0xf9, 0xa4, 0xb0, 0x99, 0x92, 0x82, 0xf8,
			0x80, 0x90, 0x88, 0x83, 0xc6, 0xa1, 0x86, 0x8e};
//	1001 1010 1011 1100 0000 0111_1111 = 0x7f

//	if(fndDigitState == 1){
//		if(msec_1 >= 5){
//			fndvalue = 0x7f & fndFont[num%10];
//		}
//		else {
//			fndvalue = fndFont[num%10];
//		}
//	}
//	else if(fndDigitState == 3){
//		if(msec_10 >= 5){
//			fndvalue = 0x7f & fndFont[num%10];
//		}
//		else {
//			fndvalue = fndFont[num%10];
//		}
//	}
//	else {
//		fndvalue = fndFont[num%10];
//	}

	if (fndDP) {
	fndData = fndFont[num] & ~(0x80); // seg dp on
	}
	else {
	fndData = fndFont[num] | 0x80; // seg dp off
	}

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
	fndDigitState = (fndDigitState +1) % 4;
	FND_DispAllOff();
	switch(fndDigitState)
	{
	case 0:
		FND_DispDigit(num%10, fndDPData & 0x01);
		FND_SelDigit(FND_DIGIT_0);
		break;
	case 1:
		FND_DispDigit(num/10 	% 10, fndDPData & 0x02);
		FND_SelDigit(FND_DIGIT_1);
		break;
	case 2:
		FND_DispDigit(num/100 	% 10, fndDPData & 0x04);
		FND_SelDigit(FND_DIGIT_2);
		break;
	case 3:
		FND_DispDigit(num/1000 	%10, fndDPData & 0x08);
		FND_SelDigit(FND_DIGIT_3);
		break;
	}
}



