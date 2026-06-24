#include "xil_printf.h"
#include "ap/StopWatch.h"

int main()
{
   StopWatch_Init();

   while (1)
   {
      StopWatch_Execute();

      /*********polling service routine***********/
      FND_Excute();
      incTick();
      delay_ms(1);
   }

   return 0;
}
