/*
 * SPI.c
 *
 *  Created on: 2026. 6. 27.
 *      Author: kccistc
 */
#include "SPI.h"

/*
 * CTRL �젅吏��뒪�꽣 珥덇린�솕
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
 * �넻�떊�븷 ��寃� �꽑�깮
 * CTRL[5:4] cs_sel 鍮꾪듃留� 蹂�寃�, �굹癒몄� 鍮꾪듃 �쑀吏�
 * cs_sel : 0~3
 */
void SPI_SelectTarget(SPI_TypeDef_t *spi, uint8_t cs_sel)
{
    spi->CTRL &= ~SPI_CTRL_CS_SEL_MASK;
    spi->CTRL |= ((uint32_t)(cs_sel & 0x3) << SPI_CTRL_CS_SEL_POS);
}

/*
 * �쟾�넚�븷 �뜲�씠�꽣瑜� TXDATA �젅吏��뒪�꽣�뿉 write
 * SPI_Start() �샇異� �쟾�뿉 諛섎뱶�떆 癒쇱� �꽭�똿�빐�빞 �븿
 */
void SPI_WriteTxData(SPI_TypeDef_t *spi, uint8_t data)
{
    spi->TXDATA = (uint32_t)data;
}

/*
 * RXDATA �젅吏��뒪�꽣�뿉�꽌 �닔�떊 �뜲�씠�꽣 read
 * �씫�뒗 �닚媛� STATUS[1] done_flag �옄�룞 �겢由ъ뼱
 */
uint8_t SPI_ReadRxData(SPI_TypeDef_t *spi)
{
    return (uint8_t)(spi->RXDATA);
}

/*
 * CTRL[0] start 鍮꾪듃 write �넂 �쟾�넚 �떆�옉
 * �븯�뱶�썾�뼱媛� 1�겢�윮 �썑 �옄�룞 �겢由ъ뼱�븯誘�濡� �냼�봽�듃�썾�뼱 �겢由ъ뼱 遺덊븘�슂
 */
void SPI_Start(SPI_TypeDef_t *spi)
{
    spi->CTRL |= SPI_CTRL_START;
}

/*
 * STATUS[0] busy 鍮꾪듃 諛섑솚
 * �쟾�넚 以� : 1
 * �쟾�넚 �셿猷� : 0
 */
uint8_t SPI_IsBusy(SPI_TypeDef_t *spi)
{
    return (spi->STATUS & SPI_STATUS_BUSY) ? 1 : 0;
}

/*
 * STATUS[1] done_flag 鍮꾪듃 諛섑솚
 * �쟾�넚 �셿猷� : 1  �넂 SPI_ReadRxData() �샇異� �떆 �옄�룞 �겢由ъ뼱
 * �쟾�넚 以�   : 0
 */
uint8_t SPI_IsDone(SPI_TypeDef_t *spi)
{
    return (spi->STATUS & SPI_STATUS_DONE) ? 1 : 0;
}

/*
 * CTRL[1] done_ie �꽭�듃 �넂 �쟾�넚 �셿猷� �떆 �씤�꽣�읇�듃 諛쒖깮
 * �씤�꽣�읇�듃 諛⑹떇�쑝濡� �룞�옉�븷 �븣 �궗�슜
 */
void SPI_EnableInterrupt(SPI_TypeDef_t *spi)
{
    spi->CTRL |= SPI_CTRL_DONE_IE;
}

/*
 * CTRL[1] done_ie �겢由ъ뼱 �넂 �씤�꽣�읇�듃 鍮꾪솢�꽦�솕
 * �뤃留� 諛⑹떇�쑝濡� �룞�옉�븷 �븣 �궗�슜
 */
void SPI_DisableInterrupt(SPI_TypeDef_t *spi)
{
    spi->CTRL &= ~SPI_CTRL_DONE_IE;
}

void SPI_DeselectTarget(SPI_TypeDef_t *spi)
{
    spi->CTRL &= ~SPI_CTRL_CS_SEL_MASK;
}
