#include "screen.h"

void KMain()
{
	SetPrintPos(0, 0);
	SetPrintColor(SCREEN_WHITE);
//	PrintChar('\n');
	int i = PrintString("TTTTTT\n");
//	PrintIntDec(i);

	PrintIntHex(15);
	
}