/*
 * interrupt.c
 *
 *  Created on: 2026. 6. 26.
 *      Author: kccistc
 */
#include "interrupt.h"
#include "../../driver/FND/FND.h"
#include "../../HAL/UART/UART.h"
#include "../../driver/LED/LED.h"
#include "../../HAL/SPI/SPI.h"

XIntc IntrController;
extern uint8_t rx_data;
extern uint8_t spi_rx_data;

void TMR_ISR(void * CallbackRef)
{
	FND_Excute();
	incTick();
}
void UART_ISR(void * CallbackRef)
{

	//uint8_t rx_data;
	rx_data = UART_Receive(UART0);
	if (rx_data == 'r') {
	LED_Toggle(0);
	}
	else if (rx_data == 'c') {
	LED_Toggle(1);
	}

}
void SPI_ISR(void *CallbackRef)
{
    spi_rx_data = SPI_ReadRxData(SPI0);  // 수신 데이터 저장 + done_flag 자동 클리어
    if(spi_rx_data == 0xAB) {
        LED_Toggle(2);
    }
    else if(spi_rx_data == 0xCD) {
        LED_Toggle(3);
    }

}

int SetupInterruptsystem()
{
	int status;
	// 1. 인터럽트 컨트롤러 초기화
	status = XIntc_Initialize(&IntrController, INTC_DEV_ID);

	if(status != XST_SUCCESS){
		return XST_FAILURE;
	}
	//2 - 1. TMR_ISR 함수를 Intc와 연결
	status = XIntc_Connect(&IntrController, TMR_VEC_ID, (XInterruptHandler)TMR_ISR, (void *)0);
	if(status != XST_SUCCESS){
		return XST_FAILURE;
	}
	//2 - 2. UART_ISR 함수를 Intc와 연결
	status = XIntc_Connect(&IntrController, UART_VEC_ID, (XInterruptHandler)UART_ISR, (void *)0);
	if(status != XST_SUCCESS){
		return XST_FAILURE;
	}
	// 2-3. SPI_ISR 함수를 Intc와 연결
	status = XIntc_Connect(&IntrController, SPI_VEC_ID, (XInterruptHandler)SPI_ISR, (void *)0);
	if(status != XST_SUCCESS){
	    return XST_FAILURE;
	}

	// 3. interrupt controller 시작
	status = XIntc_Start(&IntrController, XIN_REAL_MODE);
	if(status != XST_SUCCESS){
		return XST_FAILURE;
	}

	// 4. 각각의 인터럽트 채널 활성화
	XIntc_Enable(&IntrController, TMR_VEC_ID);
	XIntc_Enable(&IntrController, UART_VEC_ID);
	XIntc_Enable(&IntrController, SPI_VEC_ID);

	// ** 변경 없음. 5. Microblaze의 Exception 초기화 및 활성화
	Xil_ExceptionInit();
	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT, (Xil_ExceptionHandler)XIntc_InterruptHandler, &IntrController);
	Xil_ExceptionEnable();

	return 	XST_SUCCESS;

}

