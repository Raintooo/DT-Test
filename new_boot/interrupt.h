
#ifndef __INTERRUPT_H
#define __INTERRUPT_H

#include "kernel.h"

extern void (* EnableTimer)();
extern void (* SendEIO)(uint port);


void IntModInit();
int SetInitHandler(Gate* pGate, uint ifunc);
int GetInitHandler(Gate* pGate, uint* ifunc);

#endif