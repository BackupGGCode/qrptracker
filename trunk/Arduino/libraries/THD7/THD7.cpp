#include "WProgram.h"
#include "THD7.h"
#include <../NewSoftSerial/NewSoftSerial.h>
#define DEBUG false
extern NewSoftSerial rigSoftSerial(16,17);

THD7::THD7()
{
  //pass in serial port here?
  pinMode(13, OUTPUT); 

}

void THD7::assignSerial(NewSoftSerial s) {
  rigSoftSerial = s;
}

void THD7::begin(int baud) {
  rigSoftSerial.begin(baud);

}

void THD7::setLockOff() {
	rigSoftSerial.println("TXH 0");
}

void THD7::duplexOn() {
	rigSoftSerial.println("DUP 1");
}

void THD7::duplexOff() {
	rigSoftSerial.println("DUP 0");
}

void THD7::setCTCSSEncoderOn() {
	rigSoftSerial.println("CT 1");
}

void THD7::setCTCSSOff() {
	rigSoftSerial.println("CT 0");
}

void THD7::setCTCSSFreq(unsigned int freq) {
	rigSoftSerial.print("CTN ");
	rigSoftSerial.println(freq);
}

void FT817::rigComError(char * string) {
 //blink();
 Serial.print("Rigcomm error: ");
 Serial.println(string);
 //instead loop the getFreqMode until we get good data
}

void THD7::verifiedSetFreq(unsigned long freq, int band) {
  if (setFreqTest(freq, band)) {
    return;
  }
  else if (setFreqTest(freq, band)) {
      return;
    
  }
  else {
   rigComError("Serious rig setting failure");
  }
}


void THD7::rigComError(char * string) {
 //blink();
 Serial.print("Rigcomm error: ");
 Serial.println(string);
 //instead loop the getFreqMode until we get good data
}

void THD7::setMode(int mode) {
	rigSoftSerial.print("MD ");
	rigSoftSerial.println(mode);
}

byte THD7::getMode() {
	/*
 unsigned long l = getFreqMode();
 return mode;
*/
return '0';//TODO fix me.
}
  
boolean THD7::setFreqTest(unsigned long freq, int band) {
  setFreq(freq, int);
  //delay(100);
  unsigned long freqOut = getFreqMode();
  if (freqOut == freq) {

  /*Serial.print("pass: ");
  Serial.println(freqOut);
  */
   return true;
  }
  else { 
  	  if (DEBUG) {
  	    Serial.print("sent in: ");
  	    Serial.print(freq);
  	    Serial.print("got out: ");
  	    Serial.println(freqOut);
  	  }
  	   // rigComError("failed setfreqtest");
         return false;
  }
}

void THD7::setFreq(long freq, int band) {
		unsigned char foo[4];
       // char bar[] = {0x11, 0x22};
		rigSoftSerial.print("FQ 00");
		rigSoftSerial.print(freq);
		rigSoftSerial.print(",")
		rigSoftSerial.println(band);
}


unsigned long THD7::getFreqMode() {
	rigSoftSerial.println("FQ");
	char fq[14];
	int x = 0;
	unsigned long startTime = millis();
		while (fq[x] != '\n' && millis() < startTime + 2000) {
		if (risSoftSerial.available() > 0 {
			fq[x] = rigSoftSerial.read();
			x++;
		}
		
	}
	fq[x+1] = '\0';//null terminate to make string
	return atol(fq);
}







void THD7::flush() {
	rigSoftSerial.flush();
}
void THD7::off() {
//can't do it.
}

void THD7::on() {
//can't do it.
}

void THD7::setSplitModeOn() {
	rigSoftSerial.println("DUP 1");
}


void THD7::setSplitModeOff() {
	rigSoftSerial.println("DUP 0");
}

void 

//2m or 70cm?
void THD7::setHamBand(int band) {
	rigSoftSerial.print("RBN ");
	rigSoftSerial.println(band);
}

/*Band A or B */
void THD7::setBand(int band) {
	rigSoftSerial.print("BC ");
	rigSoftSerial.println(band);
}

void THD7::listenToBand(int band) {
	rigSoftSerial.print("BAL ");
	int balance = band * 4;
	rigSoftSerial.println(balance);
}

boolean THD7::txState() {
	return false;
}

void THD7::tncOff() {
	rigSoftSerial.println("TNC 0");
}

void THD7::tncOn() {
	rigSoftSerial.println("TNC 1");
}

void setBand()

