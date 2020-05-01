#include "iHandler.h"
#include "interrupt.h" 

void TimerHandler()
{
	static int i = 0;
	
	i = (i + 1) % 10;
	
	if(i == 0)
	{	
		Schedule();
	}
	
	SendEIO(MASTER_EOI_PORT);

}
