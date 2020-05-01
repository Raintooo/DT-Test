
#include "screen.h"
#include "kernel.h"
#include "interrupt.h"
#include "task.h"


void KMain()
{
	SetPrintPos(0, 0);
	SetPrintColor(SCREEN_WHITE);

	int i;
	
	PrintString("GDT Entry:");
	PrintIntHex((uint)gGdtInfo.entry);
	PrintChar('\n');
	
	PrintString("GDT Size:");
	PrintIntDec((uint)gGdtInfo.size);
	PrintChar('\n');
	
	PrintString("IDT Entry:");
	PrintIntHex((uint)gIdtInfo.entry);
	PrintChar('\n');
	
	PrintString("IDT Size:");
	PrintIntDec((uint)gIdtInfo.size);
	PrintChar('\n');
	
	PrintString("RunTask:");
	PrintIntHex((uint)RunTask);
	PrintChar('\n');

	TaskModInit();
	IntModInit();
	
	LanuchTask();

}