
#ifndef TleStoreCallback_h
#define TleStoreCallback_h

#include "WProgram.h"
#include <inttypes.h>

#define CWMODE 0
#define USB 1
#define LSB 2
#define FM 3
#define FMN 4
#define CWN 5
#define PKT 6 // packet is FM
#define NOR 0
#define REV 1

#define TLE_RECORD_SIZE 46
#define MODELINE_RECORD_SIZE 28
#define HEADER_SIZE 15
#define MAX_TLES 5000 // change this number if we are using an external EEPROM

typedef void (*writeCallback)(int, uint8_t);
typedef uint8_t (*readCallback)(int);

class TleStoreCallback
{
	public:
		TleStoreCallback(readCallback read, writeCallback write, int writeDelay);
		void handshake();
		void greeting();
		void erase();
		void echoWrite();
		void readTLE();
		void dumpStore();
		void listTlesAndModelines();
		float getLatitude();
		float getLongitude();
		unsigned int getAltitude();
		byte getVersion();
		boolean readHeader();
		unsigned int getSatAddress( byte rank);
	//	struct modelineStruct getModelineForSatNumber(int rank);
	//	struct modelineStruct getModeline(unsigned int tleAddress);
		struct tleStruct getTle(byte place);
		byte countModelinesForTle(unsigned int tleAddress);
		unsigned int getModelineStart(unsigned int tleAddress, byte modelineRank);
		struct modelineStruct getModelineForAddress(unsigned int modelineStart);
		unsigned int numberOfModelines, numberOfTles;
		
		//float latitude, longitude;
		//unsigned int altitude;
		char * getSatNameFromAddress(uint16_t satAddress);
	    void echoWriteChar(unsigned int address, char c);
 
		writeCallback write;
		readCallback read;
		int writeDelay;
	    template <class T>  int readAnything(int ee, T& value);
};

struct tleStruct
{
  char name[6]; // 6 bytes
  float   YE;
  float   TE;
  float   M2;
  float   IN;
  float   RA;
  float   EC;
  float   WP;
  float   MA;
  float   MM;
  float   RV;

};

// modeline struct
struct modelineStruct {
  uint32_t ulLong;
  uint32_t dlLong;
  char dlMode;
  char ulMode;
  char polarity;
  float ulShift;
  float dlShift;
  unsigned int tone;
  char modeName[5];
  uint16_t satAddress; //ints in arduino are 2-byte anyway
  //this limits the addressable space to 65,535 bytes = 512 kilobits
  //when using a chip like 24LC1025, it would be possible to put modelines
  // on one side and TLEs on the other, but you'd have to be clever about
 // changing the I2C address from time to time.
  char satName[6];
};


#endif
