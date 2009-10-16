#include <CW.h>
#define PIN 13

/* Here we declare our functions that indicate what happens when the 'key'
goes 'down' and when the 'key' goes 'up'. In this case, an LED attached
to pin 13 is turned on and off.
*/
void doOn() {digitalWrite(PIN,HIGH);}
void doOff() {digitalWrite(PIN,LOW);}

/* If the naming convention used above is retained, these pointers to the
   on and off functions can be kept as-is.
*/
signalFunction onPointer = &doOn;
signalFunction offPointer = &doOff;

/* Declaring the CW object, with its two on and off functions, as well as
the initial speed of the code in wpm. Note that the speed is declared in a
byte, not an int
*/
CW cw(onPointer, offPointer, byte(10));

/* In this example, we will be toggling a digital pin. Therefore, we need
to set up that pin's mode.
*/
void setup()
{
	pinMode(PIN, OUTPUT);
}


/* The main loop provides the morse code for the characters below at
increasing speed until it reaches 50 wpm, whereupon it keeps providing the code
over and over at 50 wpm.
*/
void loop()
{
	cw.signalChars("abcdefghijklmnopqrstuvwxy.?-");
	cw.faster();
}
