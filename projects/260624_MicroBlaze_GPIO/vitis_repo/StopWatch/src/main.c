#include "xil_printf.h"
#include "driver/LED/LED.h"
#include "driver/FND/FND.h"
#include "common/delay/delay.h"

typedef enum
{
   NO_ACT = 0,
   ACT_PUSHED,
   ACT_RELEASED
} button_status_e;

typedef enum
{
   RELEASED = 0,
   PUSHED
} button_state_e;

void Button_Init()
{
   uint32_t btnPort = GPIO_GetCR(GPIOB);
   btnPort &= ~(1 << 4 | 1 << 5);
   GPIO_SetMode(GPIOB, btnPort);
}

uint32_t Button_GetState()
{
   static button_state_e prevState = RELEASED;
   button_state_e curState = GPIO_ReadPin(GPIOB, GPIO_PIN_4) ? PUSHED : RELEASED;

   if (curState == PUSHED && prevState == RELEASED)
   {
      prevState = curState;
      delay_ms(5);
      return ACT_PUSHED;
   }
   else if (curState == RELEASED && prevState == PUSHED)
   {
      prevState = curState;
      delay_ms(5);
      return ACT_RELEASED;
   }
   else
   {
      return NO_ACT;
   }
}

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
         LED_PinToggle(0);
      }
      /*********polling service routine***********/
      FND_Excute();
      incTick();
      delay_ms(1);
   }

   return 0;
}
