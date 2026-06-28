#ifndef SRC_HAL_IIC_IIC_H_
#define SRC_HAL_IIC_IIC_H_

#include "xparameters.h"
#include <stdint.h>

typedef struct {
    volatile uint32_t CTRL;
    volatile uint32_t CONFIG;
    volatile uint32_t STATUS;
    volatile uint32_t DATA;
} IIC_TypeDef_t;

#define IIC0_BASEADDR XPAR_IIC_0_S00_AXI_BASEADDR
#define IIC0          ((IIC_TypeDef_t *)IIC0_BASEADDR)

#define IIC_CTRL_START     (1u << 0)
#define IIC_CTRL_RW_READ   (1u << 1)
#define IIC_CTRL_ACK_IN    (1u << 2)
#define IIC_CTRL_INTR_EN   (1u << 3)
#define IIC_CTRL_DONE_CLR  (1u << 4)

#define IIC_STATUS_BUSY      (1u << 0)
#define IIC_STATUS_DONE      (1u << 1)
#define IIC_STATUS_ACK_SEEN  (1u << 2)
#define IIC_STATUS_INTR      (1u << 3)
#define IIC_STATUS_RX_POS    8u
#define IIC_STATUS_RX_MASK   (0xffu << IIC_STATUS_RX_POS)

#define IIC_CONFIG_CLK_DIV_POS      0u
#define IIC_CONFIG_CLK_DIV_MASK     (0xffffu << IIC_CONFIG_CLK_DIV_POS)
#define IIC_CONFIG_TARGET_ADDR_POS  16u
#define IIC_CONFIG_TARGET_ADDR_MASK (0x7fu << IIC_CONFIG_TARGET_ADDR_POS)

#define IIC_DATA_TX_POS   0u
#define IIC_DATA_TX_MASK  (0xffu << IIC_DATA_TX_POS)
#define IIC_DATA_RX_POS   8u
#define IIC_DATA_RX_MASK  (0xffu << IIC_DATA_RX_POS)

#define IIC_DEFAULT_CLK_DIV 250u
#define IIC_DEFAULT_TIMEOUT 1000000u

void IIC_SetConfig(IIC_TypeDef_t *iic, uint8_t target_addr, uint16_t clk_div);
uint32_t IIC_GetConfig(IIC_TypeDef_t *iic);
void IIC_WriteTxData(IIC_TypeDef_t *iic, uint8_t data);
uint8_t IIC_ReadRxData(IIC_TypeDef_t *iic);
uint32_t IIC_GetStatus(IIC_TypeDef_t *iic);
void IIC_StartWrite(IIC_TypeDef_t *iic, uint8_t intr_en);
void IIC_StartRead(IIC_TypeDef_t *iic, uint8_t ack_in, uint8_t intr_en);
void IIC_ClearDone(IIC_TypeDef_t *iic, uint8_t intr_en);
uint32_t IIC_WaitDone(IIC_TypeDef_t *iic, uint32_t timeout);
uint8_t IIC_IsBusy(IIC_TypeDef_t *iic);
uint8_t IIC_IsDone(IIC_TypeDef_t *iic);
uint8_t IIC_IsAckSeen(IIC_TypeDef_t *iic);
uint8_t IIC_StatusIsBusy(uint32_t status);
uint8_t IIC_StatusIsDone(uint32_t status);
uint8_t IIC_StatusIsAckSeen(uint32_t status);
uint8_t IIC_StatusRxData(uint32_t status);
uint32_t IIC_WriteByte(IIC_TypeDef_t *iic, uint8_t target_addr, uint16_t clk_div, uint8_t data, uint32_t timeout);
uint32_t IIC_ReadByte(IIC_TypeDef_t *iic, uint8_t target_addr, uint16_t clk_div, uint8_t ack_in, uint8_t *data, uint32_t timeout);
uint8_t IIC_ProbeAddress(IIC_TypeDef_t *iic, uint8_t target_addr, uint16_t clk_div, uint8_t probe_data, uint32_t timeout);

#endif /* SRC_HAL_IIC_IIC_H_ */
