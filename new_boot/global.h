#ifndef __GLOBAL_H
#define __GLOBAL_H

#include "kernel.h"

extern GdtInfo gGdtInfo;
extern IdtInfo gIdtInfo;
extern void (* RunTask)(volatile Task* p);
extern void (* LoadTask)(volatile Task* p);

#endif