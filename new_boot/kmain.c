#include "global.h"
#include "screen.h"
#include "kernel.h"


void (* InitInterrupt)() = NULL;
void (* EnableTimer)() = NULL;
void (* SendEIO)(uint port) = NULL;
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
	SetPrintPos(5, 13);
	PrintString("RunTaskA:");
	while(1)
	{
		SetPrintPos(15, 13);
		PrintChar('A'+i);
		i = (i+1) % 26;
		Delay();
	}
}

void TimerHandler()
{
	static int i = 0;
	
	i = (i + 1) % 10;
	
		SetPrintPos(0,10);
		PrintString("Timer : ");
	
	if(i == 0)
	{
		static int j = 0;
		
		SetPrintPos(0,9);
		PrintString("Timer : ");
		SetPrintPos(10, 9);
		PrintIntDec(j++);
	}
	
	SendEIO(MASTER_EOI_PORT);
	
	asm volatile("leave\n""iret\n");

}

void KMain()
{
	SetPrintPos(0, 0);
	SetPrintColor(SCREEN_WHITE);

	int i;
	uint base, limit, tmp;
	ushort attr;
	
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
	
	p.rv.gs = LDT_VIDEO_SELECTOR;			// Init Task  register
	p.rv.cs = LDT_CODE32_SELECTOR;
	p.rv.es = LDT_DATA32_SELECTOR;
	p.rv.ds = LDT_DATA32_SELECTOR;
	p.rv.fs = LDT_DATA32_SELECTOR;
	p.rv.ss = LDT_DATA32_SELECTOR;
	
	p.rv.esp = (uint)(p.stack + sizeof(p.stack));
	p.rv.eip = (uint)(RunTaskA);
	p.rv.eflags = 0x3202;
	p.tss.esp0 = 0x9000;
	p.tss.ss0 = GDT_DATA32_FLAT_SELECTOR;
	p.tss.iomb = sizeof(p.tss);
	
	
	SetDescValue(p.ldt + LDT_VIDEO_INDEX, 0xB8000, 0x07FFF, DA_DRWA + DA_32 + DA_DPL3);
	SetDescValue(p.ldt + LDT_CODE32_INDEX, 0x00,    0xFFFFF, DA_C + DA_32 + DA_DPL3);
	SetDescValue(p.ldt + LDT_DATA32_INDEX, 0x00,    0xFFFFF, DA_DRW + DA_32 + DA_DPL3);
	
	p.ldtSelector = GDT_TASK_LDT_SELECTOR;
	p.tssSelector = GDT_TASK_TSS_SELECTOR;
	
	SetDescValue(&gGdtInfo.entry[GDT_TASK_LDT_INDEX], (uint)&p.ldt, sizeof(p.ldt)-1, DA_LDT + DA_DPL0);
	SetDescValue(&gGdtInfo.entry[GDT_TASK_TSS_INDEX], (uint)&p.tss, sizeof(p.tss)-1, DA_386TSS + DA_DPL0);
	
	SetInitHandler(gIdtInfo.entry + 0x20, (uint)TimerHandler);
	
	InitInterrupt();
	EnableTimer();
	
	RunTask(&p);
	
	
}