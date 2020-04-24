#include "global.h"
#include "const.h"

GdtInfo gGdtInfo = {0};
void (* RunTask)(Task* p) = NULL;
