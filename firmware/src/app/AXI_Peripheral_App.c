/*
 * AXI_Peripheral_App.c
 *
 *  Created on: 2026. 6. 24.
 *      Author: kccistc
 */


#include "AXI_Peripheral_App.h"
#include "../driver/LED/LED.h"


#define STOP_STATE_LED 	5
#define RUN_STATE_LED 	7

typedef struct {
	uint8_t hour;
	uint8_t min;
	uint8_t sec;
	uint8_t ms;
} axiPeripheralApp_t;

axiPeripheralApp_e axiPeripheralAppState;
uint32_t counter;
uint32_t axiPeripheralAppLed;
uint32_t axiPeripheralAppStateLed;
//uint32_t hour, min, sec, msec;
axiPeripheralApp_t axiPeripheralAppTimeData;

uint8_t rx_data;



void AXI_Peripheral_App_Init()
{
	LED_Init();
	FND_Init();
	Button_Init();
	axiPeripheralAppState = STOP;
	rx_data = 0;
	counter = 0;
	LED_PinOn(0);
	axiPeripheralAppLed = 0x01;
	axiPeripheralAppStateLed = 0x00;
	axiPeripheralAppTimeData.hour = 0;
	axiPeripheralAppTimeData.min = 0;
	axiPeripheralAppTimeData.sec = 0;
	axiPeripheralAppTimeData.ms = 0;
}

//1 3[2 50 5]0 -> value = 2505;

void AXI_Peripheral_App_Execute()
{
	AXI_Peripheral_App_RunTime();
	AXI_Peripheral_App_ControlState();
	AXI_Peripheral_App_DispWatch();


}

void AXI_Peripheral_App_DispWatch()
{
	if((axiPeripheralAppTimeData.ms%10) < 5) {
			FND_SetDP(FND_DIGIT_1, FND_DP_ON);
		}
		else {
			FND_SetDP(FND_DIGIT_1, FND_DP_OFF);
		}
		if((axiPeripheralAppTimeData.ms) <50) {
			FND_SetDP(FND_DIGIT_3, FND_DP_ON);
		}
		else {
			FND_SetDP(FND_DIGIT_3, FND_DP_OFF);
		}

		FND_SetNum((axiPeripheralAppTimeData.min%10 * 1000) + (axiPeripheralAppTimeData.sec * 10) + (axiPeripheralAppTimeData.ms/10 % 10));

		AXI_Peripheral_App_ControlLed();
}

void AXI_Peripheral_App_ControlState()
{
	switch(axiPeripheralAppState){
	case STOP:
		if(Button_GetState(&hbtnRunStop) == ACT_PUSHED){
			axiPeripheralAppState = RUN;
		}
		else if (Button_GetState(&hbtnClear) == ACT_PUSHED){
			axiPeripheralAppState = CLEAR;
		}
		else if (rx_data == 'r'){
			rx_data = 0;
			axiPeripheralAppState = RUN;
		}
		else if (rx_data == 'c'){
			rx_data = 0;
			axiPeripheralAppState = CLEAR;
		}

		break;
	case RUN:
		if(Button_GetState(&hbtnRunStop) == ACT_PUSHED){
			axiPeripheralAppState = STOP;
		}
		else if (rx_data == 'r'){
			rx_data = 0;
			axiPeripheralAppState = STOP;
		}
		break;
	case CLEAR:
		axiPeripheralAppState = STOP;
		AXI_Peripheral_App_ClearTime();
		break;
	default :
		axiPeripheralAppState = STOP;
		break;

	}
}

void AXI_Peripheral_App_ClearTime()
{
	axiPeripheralAppTimeData.ms = 0;
	axiPeripheralAppTimeData.sec = 0;
	axiPeripheralAppTimeData.min = 0;
	axiPeripheralAppTimeData.hour = 0;
}

void AXI_Peripheral_App_IncTime()
{
	if(axiPeripheralAppTimeData.ms == 99) {
		axiPeripheralAppTimeData.ms = 0;
	}
	else{
	axiPeripheralAppTimeData.ms++;
	return;
	}
	if(axiPeripheralAppTimeData.sec == 59) {
		axiPeripheralAppTimeData.sec = 0;
	}
	else{
	axiPeripheralAppTimeData.sec++;
	return;
	}
	if(axiPeripheralAppTimeData.min == 59) {
		axiPeripheralAppTimeData.min = 0;
	}
	else{
	axiPeripheralAppTimeData.min++;
	return;
	}
	if(axiPeripheralAppTimeData.hour == 23) {
		axiPeripheralAppTimeData.hour = 0;
	}
	else{
	axiPeripheralAppTimeData.hour++;
	return;
	}

}

void AXI_Peripheral_App_RunTime()
{
	static uint32_t prevTime = 0;
	uint32_t curTime = millis();

	if(curTime - prevTime < 10) return;
	prevTime = curTime;

	if(axiPeripheralAppState == RUN){
		counter++;
		AXI_Peripheral_App_IncTime();
	}
}



void AXI_Peripheral_App_ControlLed()
{
	switch(axiPeripheralAppState){
	case STOP:
		AXI_Peripheral_App_StopLed();
		break;
	case RUN:
		AXI_Peripheral_App_RunLed();
		break;
	case CLEAR:
		AXI_Peripheral_App_ClearLed();
		break;
	}
}

void AXI_Peripheral_App_RunLed()
{
	static uint32_t prevTime = 0;
	//	static uint8_t ledstate = 1;
	uint32_t curTime = millis();

	axiPeripheralAppStateLed &= ~(1<<STOP_STATE_LED);
	axiPeripheralAppStateLed |= (1<<RUN_STATE_LED);
	LED_WritePort8(LED_HI_GPIO,axiPeripheralAppStateLed);

	if(curTime - prevTime < 100) return;
	prevTime = curTime;

	axiPeripheralAppLed = (axiPeripheralAppLed << 1) | (axiPeripheralAppLed >> 7);
	LED_WritePort8(LED_LOW_GPIO,axiPeripheralAppLed);
}

void AXI_Peripheral_App_ClearLed()
{
	axiPeripheralAppLed = 0x01;
	LED_WritePort8(LED_LOW_GPIO,axiPeripheralAppLed);
}

void AXI_Peripheral_App_StopLed()
{
	axiPeripheralAppStateLed |= (1<<STOP_STATE_LED);
	axiPeripheralAppStateLed &= ~(1<<RUN_STATE_LED);
	LED_WritePort8(LED_HI_GPIO,axiPeripheralAppStateLed);
}
