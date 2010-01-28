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

#include "WProgram.h"
#include "Ansiterm.h"

Ansiterm::Ansiterm()
{
}


void Ansiterm::home()
{
  preamble();
  Serial.write('H');
}


void Ansiterm::xy(int x, int y)
{
  preamble();
  Serial.print(y,DEC);
  Serial.write(';');
  Serial.print(x, DEC);
  Serial.write('H');
}


void Ansiterm::up(int x)
{
  preambleAndNumberAndValue(x,'A');
}


void Ansiterm::down(int x)
{
  preambleAndNumberAndValue(x,'B');
}


void Ansiterm::forward(int x)
{
  preambleAndNumberAndValue(x,'C');
}


void Ansiterm::backward(int x)
{
  preambleAndNumberAndValue(x,'D');
}


void Ansiterm::eraseLine()
{
  preamble();
  Serial.write('2');
  Serial.write('K');
}


void Ansiterm::eraseScreen()
{
  preamble();
  Serial.write('1');
  Serial.write('J');
}


void Ansiterm::setBackgroundColor(int color)
{
  setAttribute(color + 40);
}


void Ansiterm::setForegroundColor(int color)
{
  setAttribute(color + 30);
}


void Ansiterm::boldOn()
{
  setAttribute(BOLD_ON);
}


void Ansiterm::boldOff()
{
  setAttribute(BOLD_OFF);
}


void Ansiterm::italicsOn()
{
  setAttribute(ITALICS_ON);
}


void Ansiterm::italicsOff()
{
  setAttribute(ITALICS_OFF);
}


void Ansiterm::underlineOn()
{
  setAttribute(UNDERLINE_ON);
}


void Ansiterm::underlineOff()
{
  setAttribute(UNDERLINE_OFF);
}


void Ansiterm::strikethroughOn()
{
  setAttribute(STRIKETHROUGH_ON);
}


void Ansiterm::strikethroughOff()
{
  setAttribute(STRIKETHROUGH_OFF);
}


void Ansiterm::inverseOn()
{
  setAttribute(INVERSE_ON);
}


void Ansiterm::inverseOff()
{
  setAttribute(INVERSE_OFF);
}


void Ansiterm::reset()
{
  setAttribute(RESET);
}


void Ansiterm::defaultBackground()
{
  setAttribute(DEFAULT_BACKGROUND);
}


void Ansiterm::defaultForeground()
{
  setAttribute(DEFAULT_FOREGROUND);
}


void Ansiterm::fill(int x1, int y1, int x2, int y2)
{
  for (int x = x1; x <= x2; x++)
  {
    for (int y = y1; y <= y2; y++)
    {
      xy(x,y);
      Serial.print(' ');
    }
  }
}


/* private functions */
void Ansiterm::preamble()
{
  Serial.write(ESCAPE);
  Serial.write(BRACE);
}


void Ansiterm::preambleAndNumberAndValue(int x, char v)
{
  preamble();
  Serial.print(x,DEC);
  Serial.write(v);
}


void Ansiterm::setAttribute(int a)
{
  preambleAndNumberAndValue(a, 'm');
}
