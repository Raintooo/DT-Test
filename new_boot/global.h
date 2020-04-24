#ifndef __GLOBAL_H
#define __GLOBAL_H

#include "kernel.h"

extern GdtInfo gGdtInfo;
extern void (* RunTask)(Task* p);

#endif