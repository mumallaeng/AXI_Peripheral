#ifndef SRC_HAL_SPI_HAL_SPI_H_
#define SRC_HAL_SPI_HAL_SPI_H_

#include "xparameters.h"
#include <stdint.h>

/* ���� �젅吏��뒪�꽣 援ъ“泥� �������������������������������������������������������������������������������������� */
typedef struct {
    uint32_t CTRL;    // 0x00 [0]start [1]done_ie [2]cpol [3]cpha [5:4]cs_sel [15:8]clk_div
    uint32_t TXDATA;  // 0x04 [7:0] tx_data
    uint32_t STATUS;  // 0x08 [0]busy [1]done_flag
    uint32_t RXDATA;  // 0x0C [7:0] rx_data
} SPI_TypeDef_t;

/* ���� 踰좎씠�뒪 二쇱냼 ���������������������������������������������������������������������������������������������� */
#define SPI_BASEADDR    XPAR_AXI_SPI_CONTROLLER_0_S00_AXI_BASEADDR
#define SPI0            ((SPI_TypeDef_t *) SPI_BASEADDR)

/* ���� CTRL 鍮꾪듃 �븘�뱶 ���������������������������������������������������������������������������������������� */
#define SPI_CTRL_START          (1 << 0)
#define SPI_CTRL_DONE_IE        (1 << 1)
#define SPI_CTRL_CPOL           (1 << 2)
#define SPI_CTRL_CPHA           (1 << 3)
#define SPI_CTRL_CS_SEL_POS     4
#define SPI_CTRL_CS_SEL_MASK    (0x3 << SPI_CTRL_CS_SEL_POS)
#define SPI_CTRL_CLK_DIV_POS    8
#define SPI_CTRL_CLK_DIV_MASK   (0xFF << SPI_CTRL_CLK_DIV_POS)

/* ���� STATUS 鍮꾪듃 �븘�뱶 ������������������������������������������������������������������������������������ */
#define SPI_STATUS_BUSY         (1 << 0)
#define SPI_STATUS_DONE         (1 << 1)

/* ���� �븿�닔 �꽑�뼵 �������������������������������������������������������������������������������������������������� */
void    SPI_Init(SPI_TypeDef_t *spi, uint8_t cpol, uint8_t cpha, uint8_t clk_div);
void    SPI_SelectTarget(SPI_TypeDef_t *spi, uint8_t cs_sel);
void    SPI_WriteTxData(SPI_TypeDef_t *spi, uint8_t data);
uint8_t SPI_ReadRxData(SPI_TypeDef_t *spi);
void    SPI_Start(SPI_TypeDef_t *spi);
uint8_t SPI_IsBusy(SPI_TypeDef_t *spi);
uint8_t SPI_IsDone(SPI_TypeDef_t *spi);
void    SPI_EnableInterrupt(SPI_TypeDef_t *spi);
void    SPI_DisableInterrupt(SPI_TypeDef_t *spi);
void SPI_DeselectTarget(SPI_TypeDef_t *spi);

#endif /* SRC_HAL_SPI_HAL_SPI_H_ */
