#include "WProgram.h"
#include "FT817.h"
#include <../NewSoftSerial/NewSoftSerial.h>
#define DEBUG false
extern NewSoftSerial rigSoftSerial(2,3);

FT817::FT817()
{
  //pass in serial port here?
  pinMode(13, OUTPUT); 

}

void FT817::assignSerial(NewSoftSerial s) {
  rigSoftSerial = s;
}

void FT817::begin(int baud) {
  rigSoftSerial.begin(baud);
      sendCATCommandChar(FT817_ANY_BYTE);
    sendCATCommandChar(FT817_ANY_BYTE);
    sendCATCommandChar(FT817_ANY_BYTE);
    sendCATCommandChar(FT817_ANY_BYTE);
    sendCATCommandChar(0x80);
}

void FT817::verifiedSetFreq(unsigned long freq) {
  if (setFreqTest(freq)) {
    return;
  }
  else if (setFreqTest(freq)) {
      return;
    
  }
  else {
   rigComError("Serious rig setting failure");
  }
}


void FT817::blink() {
digitalWrite(13, HIGH);   // set the LED on
   delay(500);                  // wait for a second
   digitalWrite(13, LOW);    // set the LED off
   delay(500);
   digitalWrite(13, HIGH);   // set the LED on
   delay(500);                  // wait for a second
   digitalWrite(13, LOW);    // set the LED off
   delay(500);
}
void FT817::rigComError(char * string) {
 //blink();
 Serial.print("Rigcomm error: ");
 Serial.println(string);
 //instead loop the getFreqMode until we get good data
}

void FT817::setMode(byte mode) {
  if (mode <= 8) {
  	if (DEBUG) {
  		//Serial.print(0xFE,BYTE);
  		//Serial.print(mode, BYTE);
  	}
    sendCATCommandChar(mode);
    sendCATCommandChar(FT817_ANY_BYTE);
    sendCATCommandChar(FT817_ANY_BYTE);
    sendCATCommandChar(FT817_ANY_BYTE);
    sendCATCommandChar(FT817_MODE_SET);
  }
}

byte FT817::getMode() {
 unsigned long l = getFreqMode();
 return mode;
}
  
boolean FT817::setFreqTest(unsigned long freq) {
  setFreq(freq);
  
  unsigned long freqOut = getFreqMode();
  if (freqOut == freq) {

  /*Serial.print("pass: ");
  Serial.println(freqOut);
  */
   return true;
  }
  else { 
  	    Serial.print("sent in: ");
  	    Serial.println(freq);
  	    Serial.print("got out: ");
  	    Serial.println(freqOut);
  	    rigComError("failed setfreqtest");
         return false;
  }
}

void FT817::setFreq(long freq) {
	unsigned char foo[4];
       // char bar[] = {0x11, 0x22};
  out = to_bcd_be(foo, freq, 8);
  sendCATCommandArray(out, 4);
   sendCATCommandChar(FT817_FREQ_SET);
   delay(175);
}


unsigned long FT817::getFreqMode() {
  rigSoftSerial.flush();// not sure why I have to do this.
  //check for data after setFreq
  boolean readValid = true;
  sendCATCommandChar(FT817_ANY_BYTE);
  sendCATCommandChar(FT817_ANY_BYTE);
  sendCATCommandChar(FT817_ANY_BYTE);
  sendCATCommandChar(FT817_ANY_BYTE);
  sendCATCommandChar(FT817_FREQMODE_READ);
  byte chars[4];
    delay(50);
  if  (DEBUG) {Serial.print(0xBB, BYTE);}
  for (int i = 0; i < 4; i++) {
     chars[i] = rigSoftSerial.read();  
    // delay(100);
   
     if(chars[i] > 0x99) {
	//  readValid = false;  // if any character is bad then the whole string is bad
     }
  }
  mode = rigSoftSerial.read(); 
  if (DEBUG) {Serial.print(0xBB, BYTE);}
  /*
  if (readValid == false) {
    return FT817_BAD_READ;
  }
  
  else {
  */
  
//    if (true) {Serial.print("#");}
    freq = from_bcd_be(chars, 8);
  //  Serial.print("Final result from getfreqmode: ");
  //  Serial.println(freq);
    return freq;

//}
}

void FT817::sendCATCommandChar(int command) {
	if (DEBUG) {
		Serial.print(command, BYTE);
	}
  rigSoftSerial.print(command, BYTE);
}

void FT817::sendCATCommandArray(  byte command[], int len) {
  for (int x = 0; x < len; x++) {
  	if (DEBUG) {
		Serial.print(command[x], BYTE);
	}
    rigSoftSerial.print(command[x], BYTE);
  }
}

//Protected under gpl
unsigned long FT817::from_bcd_be(const  byte bcd_data[], unsigned bcd_len)
{
	int i;
	long f = 0;

	for (i=0; i < bcd_len/2; i++) {
		f *= 10;
		f += bcd_data[i]>>4;
		f *= 10;
		f += bcd_data[i] & 0x0f;
	}
	if (bcd_len&1) {
		f *= 10;
		f += bcd_data[bcd_len/2]>>4;
	}

	return f;
}

//protected under gpl
 unsigned char * FT817::to_bcd_be( unsigned char bcd_data[], unsigned long  freq, unsigned bcd_len)
{
	int i;
	 unsigned char a;

	/* '450'/4 -> 0,4;5,0 */
	/* '450'/3 -> 4,5;0,x */

	if (bcd_len&1) {
		bcd_data[bcd_len/2] &= 0x0f;
		bcd_data[bcd_len/2] |= (freq%10)<<4;	/* NB: low nibble is left uncleared */
		freq /= 10;
	}
	for (i=(bcd_len/2)-1; i >= 0; i--) {
		a = freq%10;
		freq /= 10;
		a |= (freq%10)<<4;
		freq /= 10;
		bcd_data[i] = a;
	}

	return bcd_data;
}
