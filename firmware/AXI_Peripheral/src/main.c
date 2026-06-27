
#include "xil_printf.h"
#include "common/delay/delay.h"
#include "ap/StopWatch.h"
#include "common/interrupt/interrupt.h"
#include "HAL/TMR/TMR.h"
#include "HAL/UART/UART.h"
#include "HAL/SPI/SPI.h"
#include "driver/Button/Button.h"
#include "driver/SPI_RAM/SPI_RAM.h"
#include "driver/SW/SW.h"

int main()
{

	TMR_SetPSC(TMR0, 100-1);
	TMR_SetARR(TMR0, 1000-1);
	TMR_StartInterrupt(TMR0);
	TMR_StartTimer(TMR0);

	SPI_Init(SPI0, 0, 0, 8);      // 추가 — CPOL=0, CPHA=0, clk_div=4
	SPI_EnableInterrupt(SPI0);    // 추가 — 인터럽트 방식 사용 시

	UART_StartInterrupt(UART0);

	StopWatch_Init();
	SetupInterruptsystem();

	//	uint32_t prevTime = 0;

	while (1)
	{

		//		StopWatch_Excute();

		uint8_t sw_data = SW_GetPort();      // SW[7:0] 현재 값
		uint8_t addr    = (SW_GetPortHigh()>>6);  // SW[15:8] → addr 선택 (선택사항)

		// Left 버튼: SW값을 addr=1에 write
		if(Button_GetState(&hbtnLeft) == ACT_RELEASED) {
			SPI_RAM_Write(addr, sw_data);    // RAM[1] = SW값
			LED_WritePort8(LED_LOW_GPIO, sw_data);  // write한 값 LED 확인
		}

		// Right 버튼: addr=1에서 read → LED + FND 표시
		if(Button_GetState(&hbtnRight) == ACT_RELEASED) {
			uint8_t rd = SPI_RAM_Read(addr);
			LED_WritePort8(LED_LOW_GPIO, rd);  // LED로 확인
			FND_SetHex(rd);                  // FND로 확인 (0~255)
		}


		//		if (Button_GetState(&hbtnLeft) == ACT_RELEASED) {
		//			UART_Transmit(UART0, 'r');
		//			SPI_SelectTarget(SPI0, 0);
		//			SPI_WriteTxData(SPI0, 0xAB);
		//			SPI_Start(SPI0);
		//		}
		//		if (Button_GetState(&hbtnRight) == ACT_RELEASED) {
		//			UART_Transmit(UART0, 'c');
		//			SPI_SelectTarget(SPI0, 0);
		//			SPI_WriteTxData(SPI0, 0xCD);
		//			SPI_Start(SPI0);
		//		}
		//		if(Button_GetState(&hbtnLeft) == ACT_RELEASED) {
		//		    UART_Transmit(UART0, 'r');
		//
		//		    // Slave RAM[1]에 0xAB write
		//		    SPI_SelectTarget(SPI0, 0);
		//
		//		    SPI_WriteTxData(SPI0, 0x01);  // wr=1 (write)
		//		    SPI_Start(SPI0);
		//		    while(SPI_IsBusy(SPI0));
		//
		//		    SPI_WriteTxData(SPI0, 0x01);  // addr=1
		//		    SPI_Start(SPI0);
		//		    while(SPI_IsBusy(SPI0));
		//
		//		    SPI_WriteTxData(SPI0, 0xAB);  // data → 슬레이브 LED에 표시
		//		    SPI_Start(SPI0);
		//		    while(SPI_IsBusy(SPI0));
		//		    SPI_DeselectTarget(SPI0, 0);
		//		}
		//		if(Button_GetState(&hbtnRight) == ACT_RELEASED) {
		//		    UART_Transmit(UART0, 'c');
		//
		//		    // Slave RAM[2]에 0xCD write
		//		    SPI_SelectTarget(SPI0, 0);
		//
		//		    SPI_WriteTxData(SPI0, 0x01);  // wr=1 (write)
		//		    SPI_Start(SPI0);
		//		    while(SPI_IsBusy(SPI0));
		//
		//		    SPI_WriteTxData(SPI0, 0x02);  // addr=2
		//		    SPI_Start(SPI0);
		//		    while(SPI_IsBusy(SPI0));
		//
		//		    SPI_WriteTxData(SPI0, 0xCD);  // data → 슬레이브 LED에 표시
		//		    SPI_Start(SPI0);
		//		    while(SPI_IsBusy(SPI0));
		//		    SPI_DeselectTarget(SPI0, 0);
		//		}
		// Left 버튼 → RAM[1] = 0xAB
		//		if(Button_GetState(&hbtnLeft) == ACT_RELEASED) {
		//		    UART_Transmit(UART0, 'r');
		//		    SPI_RAM_Write(0x01, 0xAB);
		//		}
		//
		//		// Right 버튼 → RAM[2] = 0xCD
		//		if(Button_GetState(&hbtnRight) == ACT_RELEASED) {
		//		    UART_Transmit(UART0, 'c');
		//		    SPI_RAM_Write(0x02, 0xCD);
		//		}

	}

	return 0;
}
