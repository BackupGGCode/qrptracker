
#ifndef THD7_h
#define THD7_h

#include "WProgram.h"
#include <../NewSoftSerial/NewSoftSerial.h>
#define THD7_BAND_A 0
#define THD7_BAND_B 1
#define THD7_RX_BAND 0 //A is rx
#define THD7_TX_BAND 1 // B is tx
#define THD7_SIMPLEX_MODE 0
#define THD7_DUPLEX_MODE 1
#define THD7_BAND_2M 2
#define THD7_BAND_70CM 6
#define THD7_MODE_AM 1
#define THD7_MODE_FM 0

class THD7
{
  public:
	THD7();
	boolean txState();

    void flush();
    void setMode(int mode);
    void verifiedSetFreq(unsigned long freq, int band);
    byte getMode();
    boolean setFreqTest(unsigned long freq, int band);
    void setFreq(long freq, int band);
    unsigned long getFreqMode();
	void setSplitModeOn();
	void setSplitModeOff();
	void setCTCSSEncoderOn();
	void setCTCSSOff();
	void setCTCSSFreq(unsigned int);
	void switchVFO();
	void setLockOff();
	void off();
	void on();
    void assignSerial(NewSoftSerial s);
    void begin(int baud);
	void listenToBand(int band);
	void setBand(int band);
	void duplexOn();
	void duplexOff();
	void tncOff();
	void tncOn();
	void setHamBand(int band);
	void rigCommError(char * string);
  private:

};

#endif
