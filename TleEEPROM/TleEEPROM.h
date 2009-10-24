
#ifndef TleEEPROM_h
#define TleEEPROM_h

#include "WProgram.h"
#include <inttypes.h>

#define CW 0
#define USB 1
#define LSB 2
#define FM 3
#define FMN 4
#define CWN 5
#define PKT 3 // packet is FM
#define NOR 0
#define REV 1

#define TLE_RECORD_SIZE 46
#define MODELINE_RECORD_SIZE 26
#define HEADER_SIZE 4
#define MAX_TLES 25 // change this number if we are using an external EEPROM

class TleEEPROM
{
	public:
		TleEEPROM();
		void handshake();
		void greeting();
		void erase();
		void echoWrite();
		void readTLE();
		void dumpEEPROM();
		void listTlesAndModelines();
		boolean readHeader();
		unsigned int getSatAddress( int rank);
		struct modelineStruct getModelineForSatNumber(int rank);
		struct modelineStruct getModeline(unsigned int tleAddress);
	//	struct tleStruct tle;
	//	struct modelineStruct modeline;
		struct tleStruct getTle(int place);
				int numberOfModelines, numberOfTles;
	private:
		char * getSatNameFromAddress(uint16_t satAddress);
		void echoWriteChar(unsigned int address, char c);

		uint8_t read(int);
	    void write(int, uint8_t);
		template <class T>  int EEPROM_readAnything(int ee, T& value);
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
  char modeName[5];
  uint16_t satAddress; //ints in arduino are 2-byte anyway
  //this limits the addressable space to 65,535 bytes = 512 kilobits
  char satName[6];
};


#endif
