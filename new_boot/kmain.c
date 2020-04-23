#include "global.h"
#include "screen.h"
#include "kernel.h"

void KMain()
{
	SetPrintPos(0, 0);
	SetPrintColor(SCREEN_WHITE);

	int i;
	uint base, limit;
	ushort attr;
	

	for(i = 0; i < gGdtInfo.size; i++)
	{
		GetDescValue(gGdtInfo.entry + i, &base, &limit, &attr);
		
		PrintIntHex(base);
		PrintString("    ");
		PrintIntHex(limit);
		PrintString("    ");
		PrintIntHex(attr);
		PrintChar('\n');
	}
	
	
}