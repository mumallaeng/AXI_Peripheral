/*
 * AXI_Peripheral_App.h
 *
 *  Created on: 2026. 6. 24.
 *      Author: kccistc
 */

#ifndef SRC_APP_AXI_PERIPHERAL_APP_H_
#define SRC_APP_AXI_PERIPHERAL_APP_H_

#include "../driver/Button/Button.h"
#include "../driver/FND/FND.h"
#include "../driver/LED/LED.h"

typedef enum {
	STOP = 0,
	RUN,
	CLEAR
}axiPeripheralApp_e;

void AXI_Peripheral_App_Init();
void AXI_Peripheral_App_Execute();
void AXI_Peripheral_App_ControlState();
void AXI_Peripheral_App_RunLed();
void AXI_Peripheral_App_ControlLed();
void AXI_Peripheral_App_StopLed();
void AXI_Peripheral_App_ClearLed();
void AXI_Peripheral_App_RunTime();
void AXI_Peripheral_App_ClearTime();
void AXI_Peripheral_App_IncTime();
void AXI_Peripheral_App_DispWatch();

#endif /* SRC_APP_AXI_PERIPHERAL_APP_H_ */
