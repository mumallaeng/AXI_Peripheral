#include <stdio.h>
#include <stdint.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "sleep.h"

#ifndef XPAR_GPIO_1_S00_AXI_BASEADDR
#define XPAR_GPIO_1_S00_AXI_BASEADDR 0x44A10000
#endif

#define GPIOA_BASEADDR XPAR_GPIO_0_S00_AXI_BASEADDR
#define GPIOB_BASEADDR XPAR_GPIO_1_S00_AXI_BASEADDR
#define GPIO_REG(BASE, OFFSET) (*(volatile uint32_t *)((BASE) + (OFFSET)))
#define GPIOA_CR GPIO_REG(GPIOA_BASEADDR, 0X00)
#define GPIOA_IDR GPIO_REG(GPIOA_BASEADDR, 0X04)
#define GPIOA_ODR GPIO_REG(GPIOA_BASEADDR, 0X08)
#define GPIOB_CR GPIO_REG(GPIOB_BASEADDR, 0X00)
#define GPIOB_IDR GPIO_REG(GPIOB_BASEADDR, 0X04)
#define GPIOB_ODR GPIO_REG(GPIOB_BASEADDR, 0X08)
#define LED_DELAY_US 100000

static void write_leds(uint16_t pattern)
{
    GPIOA_ODR = pattern & 0x00ff;
    GPIOB_ODR = (pattern >> 8) & 0x00ff;
}

int main()
{
    init_platform();

    GPIOA_CR = 0xff;
    GPIOB_CR = 0xff;

    print("MicroBlaze GPIOA/GPIOB LED shift\n\r");

    while (1)
    {
        uint16_t led = 0x0001;

        for (int i = 0; i < 15; i++)
        {
            write_leds(led);
            usleep(LED_DELAY_US);
            led <<= 1;
        }

        for (int i = 0; i < 15; i++)
        {
            write_leds(led);
            usleep(LED_DELAY_US);
            led >>= 1;
        }
    }

    cleanup_platform();

    return 0;
}
