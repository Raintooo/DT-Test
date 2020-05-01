#include "task.h"
#include "const.h"
#include "utility.h"

void (* RunTask)(volatile Task* p) = NULL;
void (* LoadTask)(volatile Task* p) = NULL;

volatile Task* gCTaskAddr = NULL;
Task p = {0};
Task t = {0};
TSS gTSS = {0};

static void InitTask(Task* p, void(*entry)())
{
	p->rv.gs = LDT_VIDEO_SELECTOR;			// Init Task  register
	p->rv.cs = LDT_CODE32_SELECTOR;
	p->rv.es = LDT_DATA32_SELECTOR;
	p->rv.ds = LDT_DATA32_SELECTOR;
	p->rv.fs = LDT_DATA32_SELECTOR;
	p->rv.ss = LDT_DATA32_SELECTOR;
	
	p->rv.esp = (uint)(p->stack + sizeof(p->stack));
	p->rv.eip = (uint)(entry);
	p->rv.eflags = 0x3202;
	
	gTSS.esp0 = (uint)&p->rv + sizeof(p->rv);
	gTSS.ss0 = GDT_DATA32_FLAT_SELECTOR;
	gTSS.iomb = sizeof(TSS);
	
	
	SetDescValue(AddOff(p->ldt, LDT_VIDEO_INDEX), 0xB8000, 0x07FFF, DA_DRWA + DA_32 + DA_DPL3);
	SetDescValue(AddOff(p->ldt, LDT_CODE32_INDEX), 0x00,    0xFFFFF, DA_C + DA_32 + DA_DPL3);
	SetDescValue(AddOff(p->ldt, LDT_DATA32_INDEX), 0x00,    0xFFFFF, DA_DRW + DA_32 + DA_DPL3);
	
	p->ldtSelector = GDT_TASK_LDT_SELECTOR;
	p->tssSelector = GDT_TASK_TSS_SELECTOR;
	
	SetDescValue(AddOff(gGdtInfo.entry, GDT_TASK_LDT_INDEX), (uint)&p->ldt, sizeof(p->ldt)-1, DA_LDT + DA_DPL0);
	SetDescValue(AddOff(gGdtInfo.entry, GDT_TASK_TSS_INDEX), (uint)&gTSS, sizeof(gTSS)-1, DA_386TSS + DA_DPL0);	
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

void RunTaskB()
{
	int i = 0;
	SetPrintPos(5, 15);
	PrintString("RunTaskB:");
	while(1)
	{
		SetPrintPos(15, 15);
		PrintChar('0'+i);
		i = (i+1) % 10;
		Delay();
	}
}

void TaskModInit()
{
	InitTask(&t, RunTaskB);
	InitTask(&p, RunTaskA);	
}

void LanuchTask()
{
	gCTaskAddr = &p;
	
	RunTask(gCTaskAddr);	
}

void Schedule()
{
	gCTaskAddr = (gCTaskAddr == &p) ? &t : &p;
	
	gTSS.esp0 = (uint)&gCTaskAddr->rv.gs + sizeof(RegValue);
	gTSS.ss0 = GDT_DATA32_FLAT_SELECTOR;
	
	SetDescValue(&gGdtInfo.entry[GDT_TASK_LDT_INDEX], (uint)&gCTaskAddr->ldt, sizeof(gCTaskAddr->ldt)-1, DA_LDT + DA_DPL0);
	
	LoadTask(gCTaskAddr);
}



