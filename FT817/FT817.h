/*
  FT817.h - Library for flashing Morse code.
  Created by David A. Mellis, November 2, 2007.
  Released into the public domain.
*/
#ifndef FT817_h
#define FT817_h

#include "WProgram.h"
#include <../NewSoftSerial/NewSoftSerial.h>
#define FT817_FREQ_SET 0x01
#define FT817_FREQMODE_READ 0x03
#define FT817_MODE_SET 0x07
#define FT817_MODE_LSB 0x00
#define FT817_MODE_USB 0x01
#define FT817_MODE_CW 0x02
#define FT817_MODE_CWR 0x03
#define FT817_MODE_AM 0x04
#define FT817_MODE_FM 0x08
#define FT817_MODE_DIG 0x0A
#define FT817_MODE_PKT 0x0C
#define FT817_ANY_BYTE 0x00
#define FT817_BAD_READ 0
#define FT817_SERIAL_TIMEOUT_MILLIS 8000

class FT817
{
  public:
	FT817();
    void setMode(byte mode);
    void verifiedSetFreq(unsigned long freq);
    byte getMode();
    boolean setFreqTest(unsigned long freq);
    void setFreq(long freq);
    unsigned long getFreqMode();
	
    void assignSerial(NewSoftSerial s);
    void begin(int baud);
   
  private:
    void sendCATCommandChar(int command);
    void sendCATCommandArray( byte command[], int len);
    unsigned long from_bcd_be(const byte bcd_data[], unsigned bcd_len);
    unsigned char * to_bcd_be( byte bcd_data[], unsigned long freq, unsigned bcd_len);
	byte mode;
         unsigned long freq;
	unsigned char foo[4];
    unsigned char * out;
    void blink();
    void rigComError(char * string);
    //NewSoftSerial rigSoftSerial(2,3);
};

#endif
