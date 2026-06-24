#include "xil_printf.h"
#include "driver/LED/LED.h"
#include "driver/FND/FND.h"
#include "common/delay/delay.h"

int main()
{
   int counter = 0;

   LED_Init();
   FND_Init();

   uint32_t curTime, prevTime;

   while (1)
   {
      if (Button_GetState() == ACT_RELEASED)
      {
      }
      /*********polling service routine***********/
      FND_Excute();
      incTick();
      delay_ms(1);
   }

   return 0;
}
