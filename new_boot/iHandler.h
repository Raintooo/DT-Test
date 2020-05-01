
#ifndef __IHANDLER_H
#define __IHANDLER_H

#define DeclHandler(name)   void name##Entry();\
							void name()
							
DeclHandler(TimerHandler);

#endif