#include "IIC.h"

void IIC_SetConfig(IIC_TypeDef_t *iic, uint8_t target_addr, uint16_t clk_div)
{
    iic->CONFIG = (((uint32_t)(target_addr & 0x7fu)) << IIC_CONFIG_TARGET_ADDR_POS)
                | (((uint32_t)clk_div) << IIC_CONFIG_CLK_DIV_POS);
}

uint32_t IIC_GetConfig(IIC_TypeDef_t *iic)
{
    return iic->CONFIG;
}

void IIC_WriteTxData(IIC_TypeDef_t *iic, uint8_t data)
{
    iic->DATA = (uint32_t)data;
}

uint8_t IIC_ReadRxData(IIC_TypeDef_t *iic)
{
    return (uint8_t)((iic->DATA & IIC_DATA_RX_MASK) >> IIC_DATA_RX_POS);
}

uint32_t IIC_GetStatus(IIC_TypeDef_t *iic)
{
    return iic->STATUS;
}

void IIC_StartWrite(IIC_TypeDef_t *iic, uint8_t intr_en)
{
    uint32_t ctrl = IIC_CTRL_START | IIC_CTRL_ACK_IN;

    if (intr_en) {
        ctrl |= IIC_CTRL_INTR_EN;
    }

    iic->CTRL = ctrl;
}

void IIC_StartRead(IIC_TypeDef_t *iic, uint8_t ack_in, uint8_t intr_en)
{
    uint32_t ctrl = IIC_CTRL_START | IIC_CTRL_RW_READ;

    if (ack_in) {
        ctrl |= IIC_CTRL_ACK_IN;
    }
    if (intr_en) {
        ctrl |= IIC_CTRL_INTR_EN;
    }

    iic->CTRL = ctrl;
}

void IIC_ClearDone(IIC_TypeDef_t *iic, uint8_t intr_en)
{
    uint32_t ctrl = IIC_CTRL_DONE_CLR | IIC_CTRL_ACK_IN;

    if (intr_en) {
        ctrl |= IIC_CTRL_INTR_EN;
    }

    iic->CTRL = ctrl;
}

uint32_t IIC_WaitDone(IIC_TypeDef_t *iic, uint32_t timeout)
{
    uint32_t status;

    do {
        status = IIC_GetStatus(iic);
        if ((status & IIC_STATUS_DONE) != 0u) {
            return status;
        }
    } while (timeout-- != 0u);

    return status;
}

uint8_t IIC_IsBusy(IIC_TypeDef_t *iic)
{
    return (IIC_GetStatus(iic) & IIC_STATUS_BUSY) ? 1u : 0u;
}

uint8_t IIC_IsDone(IIC_TypeDef_t *iic)
{
    return (IIC_GetStatus(iic) & IIC_STATUS_DONE) ? 1u : 0u;
}

uint8_t IIC_IsAckSeen(IIC_TypeDef_t *iic)
{
    return (IIC_GetStatus(iic) & IIC_STATUS_ACK_SEEN) ? 1u : 0u;
}
