#include "utility.h"

void Delay()
{
	int i, j;
	
	for(i = 0; i < 1000; i++)
	{
		for(j = 0; j < 1000; j++)
		{
			asm volatile("nop\n");
		}
	}
}


