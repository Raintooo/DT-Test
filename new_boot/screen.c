#include "kernel.h"
#include "screen.h"

static int gPosW = 0;
static int gPosH = 0;
static PrintColor gColor = SCREEN_WHITE;

void ClearScreen()
{
	int i, j;
	
	SetPrintPos(0, 0);
	
	for(i = 0; i < SCREEN_HEIGHT; i++)
	{
		for(j = 0; j < SCREEN_WIDTH; j++)
		{
			PrintChar(' ');
		}
	}
	SetPrintPos(0, 0);
}

int SetPrintPos(short w, short h)
{
	int ret = 0;
	
	if(ret = ((w >= 0) && (w <= SCREEN_WIDTH) && (h >= 0) && (h <= SCREEN_HEIGHT)))
	{
		gPosW = w;		
		gPosH = h;
		
		unsigned short bx = SCREEN_WIDTH * gPosH + gPosW;
		asm volatile(
			"movw %0,      %%bx\n"
			"movw $0x03D4, %%dx\n"
			"movb $0x0E,   %%al\n"
			"outb %%al,    %%dx\n"
			"movw $0x03D5, %%dx\n"
			"movb %%bh,    %%al\n"
			"outb %%al,    %%dx\n"
			"movw $0x03D4, %%dx\n"
			"movb $0x0F,   %%al\n"
			"outb %%al,    %%dx\n"
			"movw $0x03D5, %%dx\n"
			"movb %%bl,    %%al\n"
			"outb %%al,    %%dx\n"
			:
			:"r"(bx)
			:"ax", "bx", "dx"
		);
	}
	
	return ret;
}

void SetPrintColor(PrintColor color)
{
	gColor = color;
}


int PrintChar(char c)
{
	int ret = 0;

	if(c == '\n' || c == '\r')
	{
		ret = SetPrintPos(0, gPosH+1);
	}
	else
	{
		int PosH = gPosH;
		int PosW = gPosW;
		
		if(ret = ((PosW >= 0) && (PosW <= SCREEN_WIDTH) && (PosH >= 0) && (PosH <= SCREEN_HEIGHT)))
		{
			int edi = (SCREEN_WIDTH * gPosH + gPosW) *2;
			char ah = gColor;
			char al = c;
			
			asm volatile(
				"movl %0,    %%edi\n"
				"movb %1,    %%ah\n"
				"movb %2,    %%al\n"
				"movw %%ax,  %%gs:(%%edi)\n"
				:
				:"r"(edi), "r"(ah), "r"(al)
				:"ax", "edi"
			);
			
			PosW++;
			if(PosW == SCREEN_WIDTH)
			{
				PosW = 0;
				PosH++;
			}
		}
	
		SetPrintPos(PosW, PosH);
	}
	
	return ret;
}


int PrintString(const char* s)
{
	int ret = 0;
	
	if(s != NULL)
	{
		while(*s)
		{
			ret += PrintChar(*s);
			s++;
		}
	}
	else
	{
		ret = -1;
	}
	
	return ret;
}


int PrintIntDec(int n)
{
	int ret = 0;
	
	if(n < 0)
	{
		ret += PrintChar('-');
		n = -n;
		PrintIntDec(n);
	}
	else
	{
		if(n < 10)
		{
			PrintChar('0'+n);
		}
		else
		{
			PrintIntDec(n/10);
			PrintIntDec(n%10);
		}
	}
	return ret;
}

int PrintIntHex(unsigned int n)
{
	int ret = 0, i;
	char s[11] = {'0', 'x'};
	
	int low4 = n & 0xF;
	
	for(i = 9; i >= 2; i--)
	{
		low4 = n & 0xF;
		
		if(low4 < 10)
		{
			s[i] = '0' + low4;
		}
		else
		{
			s[i] = 'A' + low4 - 10;
		}	
		
		n = n >> 4;
	}

	
	ret = PrintString(s);
	
	return ret;
}







