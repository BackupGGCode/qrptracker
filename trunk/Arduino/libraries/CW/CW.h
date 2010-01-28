
#ifndef CW_h
#define CW_h

#include "WProgram.h"
typedef void (*signalFunction)(void);

class CW
{
	public:
	//	CW();
	//	CW(signalFunction callbackOn, signalFunction callbackOff, int _dit_in);
		CW( signalFunction signalOn, signalFunction signalOff, byte wpm);
		void signalChars(char in[]);
		void signalChar(char in);
		void setSpeed(byte wpm_in);
		void faster();
		void slower();
		byte getSpeed();
	private:
		void dah();
		void dit();
		int _dit_ms;
		void interEl();
		void interChar();
		int _pin;
		signalFunction callbackOn;
		signalFunction callbackOff;
		byte wpm;
};
#endif
