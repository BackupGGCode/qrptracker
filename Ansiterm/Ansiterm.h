/* 
Ansiterm.cpp -- an Arduino library that simplifies using the ANSI terminal
control escape sequences. This allows your code to  position text exactly in the
terminal, to add colour and other effects. To use Ansiterm, an ANSI terminal must
be connected to the Arduino's serial port. The terminal built into the Arduino 
IDE does not respond to the ANSI codes, but most MacOs and Linux terminals do. 
In Windows, I read that Hyperterm responds to ANSI codes. Realterm responds to most
codes, but will not change the color of the foreground.

The accompanying example file illustrates the library's use.

Copyright (c) 2009 Bruce Robertson, VE9QRP. All rights reserved.

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

#ifndef Ansiterm_h
#define Ansiterm_h
#include "WProgram.h"
#define ESCAPE 0x1B
#define BRACE '['
#define BLACK 0
#define RED 1
#define	GREEN 2
#define YELLOW 3
#define BLUE 4
#define MAGENTA 5
#define CYAN 6 
#define WHITE 7
#define BOLD_ON 1
#define BOLD_OFF 22
#define UNDERLINE_ON 4
#define UNDERLINE_OFF 24
#define ITALICS_ON 3
#define ITALICS_OFF 23
#define STRIKETHROUGH_ON 9
#define STRIKETHROUGH_OFF 29
#define INVERSE_ON 7
#define INVERSE_OFF 27
#define RESET 1
#define DEFAULT_FOREGROUND 39
#define DEFAULT_BACKGROUND 49


class Ansiterm {
	
public:
	Ansiterm();
	void home();
	void xy(int x, int y);
	void up(int x); 
	void down(int x);
	void forward(int x);
	void backward(int x);
	void eraseLine();
	void eraseScreen();
	void setBackgroundColor(int color);
	void setForegroundColor(int color);
        void boldOn();
        void boldOff();
        void underlineOn();
        void underlineOff();
        void italicsOn();
        void italicsOff();
        void strikethroughOn();
        void strikethroughOff();
        void inverseOn();
        void inverseOff();
        void reset();
        void defaultBackground();
        void defaultForeground();
        void fill(int x1, int y1, int x2, int y2);
private:
	void preamble();
	void preambleAndNumberAndValue(int x, char v);
	void setAttribute(int a);
	
};
#endif
