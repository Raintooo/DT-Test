#ifndef __KERNEL_H
#define __KERNEL_H

#include "type.h"
#include "const.h"

typedef struct 
{
    ushort limit1;
    ushort base1;
    byte   base2;
    byte   attr1;
    byte   attr2_limit2;
    byte   base3;	
}Descriptor;

typedef struct 
{
	Descriptor* const entry;
	const int size;
}GdtInfo;

typedef struct
{
	ushort offset1;
	ushort selector;
	byte   count;
	byte   attr;
	ushort offset2;
}Gate;

typedef struct
{
	Gate* entry;
	const int size;
}IdtInfo;


extern GdtInfo gGdtInfo;
extern IdtInfo gIdtInfo;


int SetDescValue(Descriptor* pDesc, uint base, uint limit, ushort attr);
int GetDescValue(Descriptor* pDesc, uint* pbase, uint* plimit, ushort* pattr);
int SetInitHandler(Gate* pGate, uint ifunc);
int GetInitHandler(Gate* pGate, uint* ifunc);

#endif





