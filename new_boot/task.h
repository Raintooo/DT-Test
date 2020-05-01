
#ifndef __TASK_H
#define __TASK_H

#include "kernel.h"

typedef struct
{
	uint previous;
	uint esp0;
	uint ss0;
	uint unused[22];
	ushort reserved;
	ushort iomb;
}TSS;

typedef struct
{
	uint gs;
	uint fs;	
	uint es;
	uint ds;	
	uint edi;
	uint esi;
	uint ebp;
	uint kesp;
	uint ebx;
	uint edx;
	uint ecx;
	uint eax;
	uint raddr;
	uint eip;
	uint cs;
	uint eflags;
	uint esp;
	uint ss;
}RegValue;

typedef struct 
{
	RegValue rv;
	Descriptor ldt[3];
	ushort ldtSelector;
	ushort tssSelector;
	uint id;
	char name[8];
	byte stack[512];
}Task;

extern void (* RunTask)(volatile Task* p);
extern void (* LoadTask)(volatile Task* p);

void TaskModInit();
void LanuchTask();
void Schedule();


#endif