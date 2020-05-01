#include "interrupt.h"
#include "utility.h"
#include "iHandler.h"

void (* InitInterrupt)() = NULL;
void (* EnableTimer)() = NULL;
void (* SendEIO)(uint port) = NULL;


void IntModInit()
{
	SetInitHandler(AddOff(gIdtInfo.entry, 0x20), (uint)TimerHandlerEntry);
	
	InitInterrupt();
	EnableTimer();
}

int SetInitHandler(Gate* pGate, uint ifunc)
{
	int ret = 0;
	
	if( ret = (pGate != NULL))
	{
		pGate->offset1 = ifunc & 0xFFFF;
		pGate->selector = GDT_CODE32_FLAT_SELECTOR;
		pGate->count = 0;
		pGate->attr = DA_386IGate + DA_DPL0;
		pGate->offset2 = (ifunc >> 16) & 0xFFFF;
	}
	
	return ret;
}

int GetInitHandler(Gate* pGate, uint* ifunc)
{
	int ret = 0;
	
	if( ret = ((pGate != NULL) && (ifunc != NULL)))
	{
		*ifunc = (pGate->offset1) | (pGate->offset2 << 16);
	}
	
	return ret;
}