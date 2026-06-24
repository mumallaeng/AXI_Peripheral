#include "xil_printf.h"
#include "driver/LED/LED.h"
#include "driver/FND/FND.h"
#include "driver/button/button.h"
#include "common/delay/delay.h"

int main()
{
   LED_Init();
   FND_Init();
   Button_Init();

   while (1)
   {
      if (Button_GetState(&hbtnRunStop) == ACT_RELEASED)
      {
         LED_PinToggle(0);
      }
      if (Button_GetState(&hbtnClear) == ACT_RELEASED)
      {
         LED_PinToggle(2);
      }
      /*********polling service routine***********/
      FND_Excute();
      incTick();
      delay_ms(1);
   }

   return 0;
}
