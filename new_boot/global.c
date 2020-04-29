#include "global.h"
#include "const.h"

GdtInfo gGdtInfo = {0};
IdtInfo gIdtInfo = {0};
void (* RunTask)(volatile Task* p) = NULL;
void (* LoadTask)(volatile Task* p) = NULL;