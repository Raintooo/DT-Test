#include "kernel.h"

GdtInfo gGdtInfo = {0};
IdtInfo gIdtInfo = {0};

int SetDescValue(Descriptor* pDesc, uint base, uint limit, ushort attr)
{
	int ret;
	
	if(ret = (pDesc != NULL))
	{
		pDesc->limit1 = limit & 0xFFFF;
		pDesc->base1 = base & 0xFFFF;
		pDesc->base2 = (base >> 16) & 0xFF;
		pDesc->attr1 = attr & 0xFF;
		pDesc->attr2_limit2 = ((attr >> 8) & 0xF0) | ((limit >> 16) & 0xF);
		pDesc->base3 = (base >> 24) & 0xFF;
	}
	
	return ret;
}

int GetDescValue(Descriptor* pDesc, uint* pbase, uint* plimit, ushort* pattr)
{
	int ret;
	
	if(ret = (pDesc && pbase && plimit && pattr))
	{
		*pbase = (pDesc->base3 << 24) | (pDesc->base2 << 16) | pDesc->base1;
		*plimit = ((pDesc->attr2_limit2 & 0xF) << 16) | pDesc->limit1;
		*pattr = ((pDesc->attr2_limit2 & 0xF0) << 8) | pDesc->attr1;
	}
	
	return ret;
}

