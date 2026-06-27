
#include "xil_printf.h"
#include "common/delay/delay.h"
#include "app/AXI_Peripheral_App.h"
#include "common/interrupt/interrupt.h"
#include "HAL/TMR/TMR.h"
#include "HAL/UART/UART.h"
#include "driver/Button/Button.h"

int main()
{

	TMR_SetPSC(TMR0, 100-1);
	TMR_SetARR(TMR0, 1000-1);
	TMR_StartInterrupt(TMR0);
	TMR_StartTimer(TMR0);

	UART_StartInterrupt(UART0);

	AXI_Peripheral_App_Init();
	SetupInterruptsystem();

	//	uint32_t prevTime = 0;

	while (1)
	{

		AXI_Peripheral_App_Execute();

		if (Button_GetState(&hbtnLeft) == ACT_RELEASED) {
		UART_Transmit(UART0, 'r');
		}
		if (Button_GetState(&hbtnRight) == ACT_RELEASED) {
		UART_Transmit(UART0, 'c');
		}


//		if (Button_GetState(&hbtnLeft) == ACT_RELEASED) {
//			UART_Transmit(UART0, 'a');
//			if (UART_Receive(UART0) == 'a')
//				LED_Toggle(5);
//		}
//
//		if (Button_GetState(&hbtnRight) == ACT_RELEASED) {
//			UART_Transmit(UART0, 'a');
//			if (UART_Receive(UART0) == 'a')
//				LED_Toggle(1);
//		}
		//		UART_Transmit(UART0, 'a');
		//		if(UART_Receive(UART0) == 'b')
		//			LED_Toggle(3);
		//
		////		delay_ms(200);
		//
		//		if (millis() - prevTime > 1000) {
		//			prevTime = millis();
		//			// LED_PinOn(2);
		//			LED_Toggle(2);
		//		}

		/*********polling service routine***********/
		//		FND_Execute();
		//		incTick();
		//		delay_ms(1);
	}

	return 0;
}
