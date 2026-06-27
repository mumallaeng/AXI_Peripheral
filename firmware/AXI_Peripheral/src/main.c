
#include "xil_printf.h"
#include "common/delay/delay.h"
#include "ap/StopWatch.h"
#include "common/interrupt/interrupt.h"
#include "HAL/TMR/TMR.h"
#include "HAL/UART/UART.h"
#include "HAL/SPI/SPI.h"
#include "driver/Button/Button.h"

int main()
{

	TMR_SetPSC(TMR0, 100-1);
	TMR_SetARR(TMR0, 1000-1);
	TMR_StartInterrupt(TMR0);
	TMR_StartTimer(TMR0);

	SPI_Init(SPI0, 0, 0, 4);      // 추가 — CPOL=0, CPHA=0, clk_div=4
	SPI_EnableInterrupt(SPI0);    // 추가 — 인터럽트 방식 사용 시

	UART_StartInterrupt(UART0);

	StopWatch_Init();
	SetupInterruptsystem();

	//	uint32_t prevTime = 0;

	while (1)
	{

		StopWatch_Excute();

//		if (Button_GetState(&hbtnLeft) == ACT_RELEASED) {
//			UART_Transmit(UART0, 'r');
//			SPI_SelectSubordinate(SPI0, 0);
//			SPI_WriteTxData(SPI0, 0xAB);
//			SPI_Start(SPI0);
//		}
//		if (Button_GetState(&hbtnRight) == ACT_RELEASED) {
//			UART_Transmit(UART0, 'c');
//			SPI_SelectSubordinate(SPI0, 0);
//			SPI_WriteTxData(SPI0, 0xCD);
//			SPI_Start(SPI0);
//		}
		if(Button_GetState(&hbtnLeft) == ACT_RELEASED) {
		    UART_Transmit(UART0, 'r');

		    // Subordinate RAM[1]에 0xAB write
		    SPI_SelectSubordinate(SPI0, 0);

		    SPI_WriteTxData(SPI0, 0x01);  // wr=1 (write)
		    SPI_Start(SPI0);
		    while(SPI_IsBusy(SPI0));

		    SPI_WriteTxData(SPI0, 0x01);  // addr=1
		    SPI_Start(SPI0);
		    while(SPI_IsBusy(SPI0));

		    SPI_WriteTxData(SPI0, 0xAB);  // data → Subordinate LED에 표시
		    SPI_Start(SPI0);
		    while(SPI_IsBusy(SPI0));
		}
		if(Button_GetState(&hbtnRight) == ACT_RELEASED) {
		    UART_Transmit(UART0, 'c');

		    // Subordinate RAM[2]에 0xCD write
		    SPI_SelectSubordinate(SPI0, 0);

		    SPI_WriteTxData(SPI0, 0x01);  // wr=1 (write)
		    SPI_Start(SPI0);
		    while(SPI_IsBusy(SPI0));

		    SPI_WriteTxData(SPI0, 0x02);  // addr=2
		    SPI_Start(SPI0);
		    while(SPI_IsBusy(SPI0));

		    SPI_WriteTxData(SPI0, 0xCD);  // data → Subordinate LED에 표시
		    SPI_Start(SPI0);
		    while(SPI_IsBusy(SPI0));
		}

	}

	return 0;
}
