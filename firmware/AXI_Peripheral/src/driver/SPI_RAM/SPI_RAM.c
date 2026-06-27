/*
 * SPI_RAM.c
 *
 *  Created on: 2026. 6. 27.
 *      Author: kccistc
 */
#include "SPI_RAM.h"

void SPI_RAM_Init(void) {
	 SPI_Init(SPI0, 0, 0, 4);
}

// Slave RAM[addr] = data
void SPI_RAM_Write(uint8_t addr, uint8_t data) {
    SPI_SelectTarget(SPI0, 0);          // CS_n LOW

    SPI_WriteTxData(SPI0, SPI_CMD_WRITE);
    SPI_Start(SPI0);
    while(SPI_IsBusy(SPI0));

    SPI_WriteTxData(SPI0, addr);
    SPI_Start(SPI0);
    while(SPI_IsBusy(SPI0));

    SPI_WriteTxData(SPI0, data);
    SPI_Start(SPI0);
    while(SPI_IsBusy(SPI0));

    SPI_DeselectTarget(SPI0);        // CS_n HIGH
}

// Slave RAM[addr] read
uint8_t SPI_RAM_Read(uint8_t addr) {
    uint8_t rx;

    SPI_SelectTarget(SPI0, 0);          // CS_n LOW

    SPI_WriteTxData(SPI0, SPI_CMD_READ);
    SPI_Start(SPI0);
    while(SPI_IsBusy(SPI0));

    SPI_WriteTxData(SPI0, addr);
    SPI_Start(SPI0);
    while(SPI_IsBusy(SPI0));

    SPI_WriteTxData(SPI0, 0x00);        // dummy byte (clock ¹ß»ý¿ë)
    SPI_Start(SPI0);
    while(SPI_IsBusy(SPI0));

    rx = SPI_ReadRxData(SPI0);

    SPI_DeselectTarget(SPI0);        // CS_n HIGH

    return rx;
}

