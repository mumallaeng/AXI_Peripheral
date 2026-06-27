/*
 * SPI_RAM.h
 *
 *  Created on: 2026. 6. 27.
 *      Author: kccistc
 */

#ifndef SRC_DRIVER_SPI_RAM_SPI_RAM_H_
#define SRC_DRIVER_SPI_RAM_SPI_RAM_H_

#include "../../HAL/SPI/SPI.h"
#include <stdint.h>

// 3바이트 프로토콜 커맨드
#define SPI_CMD_WRITE  0x01
#define SPI_CMD_READ   0x00

void    SPI_RAM_Init(void);
void    SPI_RAM_Write(uint8_t addr, uint8_t data);
uint8_t SPI_RAM_Read(uint8_t addr);

#endif /* SRC_DRIVER_SPI_RAM_SPI_RAM_H_ */
