/* CW.cpp -- a flexible library for signaling international morse code.

Copyright (c) 2009 Bruce Robertson, VE9QRP. All rights reserved.

Please install
This library requires the use of callback functions in the manner described in
the accompanying example file. With null callback functions, that is, when it is doing nothing,
 the library takes
1650 bytes. Practical applications, such as signaling with a led connected to
a pin, require around 1880 bytes.

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Lesser General Public License as published by the Free
Software Foundation; either version 2.1 of the License, or (at your option)
any later version.

This library is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
details.

You should have received a copy of the GNU Lesser General Public License along
with this library; if not, write to the Free Software Foundation, Inc., 51
Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

The latest version of this software is available at
*/
//#include "WProgram.h"
#include "CW.h"
#define  SPEED_FACTOR 2500
#define UPPER_SPEED_LIMIT 50
#define DEBUG false

/*
CW::CW()
{
	_dit_ms = 50;
}

CW::CW( signalFunction signalOn, signalFunction signalOff, int _dit_ms_in) {
	_dit_ms = _dit_ms_in;
	callbackOn = signalOn;
	callbackOff = signalOff;
}
*/

CW::CW( signalFunction signalOn, signalFunction signalOff, byte wpm_in)
{
	setSpeed(wpm_in);
	wpm = wpm_in;
	callbackOn = signalOn;
	callbackOff = signalOff;
}


void CW::setSpeed(byte wpm_in)
{
	wpm = wpm_in;
	_dit_ms = SPEED_FACTOR / wpm;
}


byte CW::getSpeed()
{
	return wpm;

}


void CW::faster()
{
	if (wpm < UPPER_SPEED_LIMIT)
	{
		setSpeed(wpm + 1);
	}
}


void CW::slower()
{
	if (wpm > 1)
	{
		setSpeed(wpm - 1);
	}
}


void CW::signalChars(char in[])
{
	if (DEBUG)
	{
		Serial.print("_dit_ms: ");
		Serial.print(_dit_ms);
		Serial.print(" = ");
		Serial.print(wpm, DEC);
		Serial.println(" wpm");
	}
	int x = 0;
	while (in[x] !=  0)
	{
		signalChar(in[x]);
		x++;
	}
}


								 // convert to lowercase
void CW::signalChar(char character)
{
	if (96  < character && character < 123)
	{
		character -= 32;
	}

	//Serial.print(character);
	switch (character)
	{
		case 'A':
			dit();
			dah();
			break;
		case 'B':
			dah();
			dit();
			dit();
			dit();
			break;
		case 'C':
			dah();
			dit();
			dah();
			dit();
			break;
		case 'D':
			dah();
			dit();
			dit();
			break;
		case 'E':
			dit();
			break;
		case 'F':
			dit();
			dit();
			dah();
			dit();
			break;
		case 'G':
			dah();
			dah();
			dit();
			break;
		case 'H':
			dit();
			dit();
			dit();
			dit();
			break;
		case 'I':
			dit();
			dit();
			break;
		case 'J':
			dit();
			dah();
			dah();
			dah();
			break;
		case 'K':
			dah();
			dit();
			dah();
			break;
		case 'L':
			dit();
			dah();
			dit();
			dit();
			break;
		case 'M':
			dah();
			dah();
			break;
		case 'N':
			dah();
			dit();
			break;
		case 'O':
			dah();
			dah();
			dah();
			break;
		case 'P':
			dit();
			dah();
			dah();
			dit();
			break;
		case 'Q':
			dah();
			dah();
			dit();
			dah();
			break;
		case 'R':
			dit();
			dah();
			dit();
			break;
		case 'S':
			dit();
			dit();
			dit();
			break;
		case 'T':
			dah();
			break;
		case 'U':
			dit();
			dit();
			dah();
			break;
		case 'V':
			dit();
			dit();
			dit();
			dah();
			break;
		case 'W':
			dit();
			dah();
			dah();
			break;
		case 'X':
			dah();
			dit();
			dit();
			dah();
			break;
		case 'Y':
			dah();
			dit();
			dah();
			dah();
			break;
		case 'Z':
			dah();
			dah();
			dit();
			dit();
			break;
		case '1':
			dit();
			dah();
			dah();
			dah();
			dah();
			break;
		case '2':
			dit();
			dit();
			dah();
			dah();
			dah();
			break;
		case '3':
			dit();
			dit();
			dit();
			dah();
			dah();
			break;
		case '4':
			dit();
			dit();
			dit();
			dit();
			dah();
			break;
		case '5':
			dit();
			dit();
			dit();
			dit();
			dit();
			break;
		case '6':
			dah();
			dit();
			dit();
			dit();
			dit();
			break;
		case '7':
			dah();
			dah();
			dit();
			dit();
			dit();
			break;
		case '8':
			dah();
			dah();
			dah();
			dit();
			dit();
			break;
		case '9':
			dah();
			dah();
			dah();
			dah();
			dit();
			break;
		case '0':
			dah();
			dah();
			dah();
			dah();
			dah();
			break;
		case ' ':
			interChar();
			break;
		case ',':
			dah();
			dah();
			dit();
			dit();
			dah();
			dah();
			break;
		case '/':
			dah();
			dit();
			dit();
			dah();
			dit();
			break;
		case '.':
			dit();
			dah();
			dit();
			dah();
			dit();
			dah();
			break;
		case '?':
			dit();
			dit();
			dah();
			dah();
			dit();
			dit();
			break;
	}
	interChar();
}


void CW::dah()
{
	callbackOn();
	delay(_dit_ms * 3);
	callbackOff();
	interEl();
}


void CW::dit()
{
	callbackOn();
	delay(_dit_ms);
	callbackOff();
	interEl();
}


void CW::interEl()
{
	delay(_dit_ms);
}


void CW::interChar()
{
	delay(_dit_ms * 2);
}
