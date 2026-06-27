/*
 * SPI.c
 *
 *  Created on: 2026. 6. 27.
 *      Author: kccistc
 */
#include "SPI.h"

/*
 * CTRL 레지스터 초기화
 * cpol  : clock polarity  (0 = idle low,  1 = idle high)
 * cpha  : clock phase     (0 = 1st edge,  1 = 2nd edge)
 * clk_div : SCLK = clk / (2 * (clk_div + 1))
 */
void SPI_Init(SPI_TypeDef_t *spi, uint8_t cpol, uint8_t cpha, uint8_t clk_div)
{
    spi->CTRL = 0;
    if(cpol) spi->CTRL |= SPI_CTRL_CPOL;
    if(cpha) spi->CTRL |= SPI_CTRL_CPHA;
    spi->CTRL |= ((uint32_t)clk_div << SPI_CTRL_CLK_DIV_POS);
}

/*
 * 통신할 타겟 선택
 * CTRL[5:4] cs_sel 비트만 변경, 나머지 비트 유지
 * cs_sel : 0~3
 */
void SPI_SelectTarget(SPI_TypeDef_t *spi, uint8_t cs_sel)
{
    spi->CTRL &= ~SPI_CTRL_CS_SEL_MASK;
    spi->CTRL |= ((uint32_t)(cs_sel & 0x3) << SPI_CTRL_CS_SEL_POS);
}

/*
 * 전송할 데이터를 TXDATA 레지스터에 write
 * SPI_Start() 호출 전에 반드시 먼저 세팅해야 함
 */
void SPI_WriteTxData(SPI_TypeDef_t *spi, uint8_t data)
{
    spi->TXDATA = (uint32_t)data;
}

/*
 * RXDATA 레지스터에서 수신 데이터 read
 * 읽는 순간 STATUS[1] done_flag 자동 클리어
 */
uint8_t SPI_ReadRxData(SPI_TypeDef_t *spi)
{
    return (uint8_t)(spi->RXDATA);
}

/*
 * CTRL[0] start 비트 write → 전송 시작
 * 하드웨어가 1클럭 후 자동 클리어하므로 소프트웨어 클리어 불필요
 */
void SPI_Start(SPI_TypeDef_t *spi)
{
    spi->CTRL |= SPI_CTRL_START;
}

/*
 * STATUS[0] busy 비트 반환
 * 전송 중 : 1
 * 전송 완료 : 0
 */
uint8_t SPI_IsBusy(SPI_TypeDef_t *spi)
{
    return (spi->STATUS & SPI_STATUS_BUSY) ? 1 : 0;
}

/*
 * STATUS[1] done_flag 비트 반환
 * 전송 완료 : 1  → SPI_ReadRxData() 호출 시 자동 클리어
 * 전송 중   : 0
 */
uint8_t SPI_IsDone(SPI_TypeDef_t *spi)
{
    return (spi->STATUS & SPI_STATUS_DONE) ? 1 : 0;
}

/*
 * CTRL[1] done_ie 세트 → 전송 완료 시 인터럽트 발생
 * 인터럽트 방식으로 동작할 때 사용
 */
void SPI_EnableInterrupt(SPI_TypeDef_t *spi)
{
    spi->CTRL |= SPI_CTRL_DONE_IE;
}

/*
 * CTRL[1] done_ie 클리어 → 인터럽트 비활성화
 * 폴링 방식으로 동작할 때 사용
 */
void SPI_DisableInterrupt(SPI_TypeDef_t *spi)
{
    spi->CTRL &= ~SPI_CTRL_DONE_IE;
}