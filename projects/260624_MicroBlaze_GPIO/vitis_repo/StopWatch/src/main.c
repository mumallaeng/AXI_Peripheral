#include "sleep.h"
#include "xil_printf.h"
#include "driver/LED/LED.h"
#include "driver/FND/FND.h"
#include "common/delay/delay.h"

int main()
{
   int counter = 0;
   uint16_t ledState = 1;

   LED_Init();
   FND_Init();

   while (1)
   {
      xil_printf("counter = %d\n", counter++);

      // ledState = (ledState << 1) | (ledState >> 15);
      ledState = (ledState >> 1) | (ledState << 15);
      LED_WritePort16(ledState);
      // LED_PinToggle(5);

      // GPIO_WritePort(FND_COM_GPIO, 0x00);
      // FND_SelDigit(FND_DIGIT_3);
      // FND_DispDigit(counter % 10, 0);

      // FND_DispNum(counter);
      // usleep(300000);

      FND_SetNum(1234);

      /* ********************************* */
      FND_Excute();
      incTick();
      delay_ms(1);
   }

   return 0;
}
