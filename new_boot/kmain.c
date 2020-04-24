#include "global.h"
#include "screen.h"
#include "kernel.h"

Task p = {0};

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

void RunTaskA()
{
	int i = 0;
	SetPrintPos(5, 10);
	PrintString("RunTaskA:");
	while(1)
	{
		SetPrintPos(15, 10);
		PrintChar('A'+i);
		i = (i+1) % 26;
		Delay();
	}
}

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
	
	PrintString("RunTask:");
	PrintIntHex((uint)RunTask);
	
	
	p.rv.gs = LDT_VIDEO_SELECTOR;
	p.rv.cs = LDT_CODE32_SELECTOR;
	p.rv.es = LDT_DATA32_SELECTOR;
	p.rv.ds = LDT_DATA32_SELECTOR;
	p.rv.fs = LDT_DATA32_SELECTOR;
	p.rv.ss = LDT_DATA32_SELECTOR;
	
	p.rv.esp = (uint)(p.stack + sizeof(p.stack));
	p.rv.eip = (uint)(RunTaskA);
	p.rv.eflags = 0x3002;
	p.tss.esp0 = 0;
	p.tss.ss0 = GDT_DATA32_FLAT_SELECTOR;
	p.tss.iomb = sizeof(p.tss);
	
	
	SetDescValue(p.ldt + LDT_VIDEO_INDEX, 0xB8000, 0x07FFF, DA_DRWA + DA_32 + DA_DPL3);
	SetDescValue(p.ldt + LDT_CODE32_INDEX, 0x00,    0xFFFFF, DA_C + DA_32 + DA_DPL3);
	SetDescValue(p.ldt + LDT_DATA32_INDEX, 0x00,    0xFFFFF, DA_DRW + DA_32 + DA_DPL3);
	
	p.ldtSelector = GDT_TASK_LDT_SELECTOR;
	p.tssSelector = GDT_TASK_TSS_SELECTOR;
	
	SetDescValue(&gGdtInfo.entry[GDT_TASK_LDT_INDEX], (uint)&p.ldt, sizeof(p.ldt)-1, DA_LDT + DA_DPL0);
	SetDescValue(&gGdtInfo.entry[GDT_TASK_TSS_INDEX], (uint)&p.tss, sizeof(p.tss)-1, DA_386TSS + DA_DPL0);
	
	
	
	RunTask(&p);
	
	
}