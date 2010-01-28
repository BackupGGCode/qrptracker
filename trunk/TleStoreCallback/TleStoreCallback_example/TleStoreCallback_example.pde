#include <TleStoreCallback.h>
#include <avr/eeprom.h>
#define WRITE_DELAY
void write(int address, uint8_t value)
{
	eeprom_write_byte((unsigned char *) address, value);
}

uint8_t read(int address)
{
	return eeprom_read_byte((unsigned char *) address);
}

readCallback in = &read;
writeCallback out = &write;
TleStoreCallback te(in, out, 50);

void setup() {
  pinMode(13, OUTPUT); 
  Serial.begin(38400);  
  te.greeting(); // this is necessary to ensure syncing with the server program
}


void loop() {
  while (Serial.available() < 1) {
    ;
  }

  if (Serial.available()) {
    char value = Serial.read();
    if (value == 'D') { 
      te.dumpStore(); 
    }

    if (value == 'T') {
      te.listTlesAndModelines();
    }
    if (value == 'E') {
      te.erase();
    }
    if (value == 'R') {
    //The former of these is meant to calculate the needed bytes and
// stop reading when they arrive. However, it doesn't seem to do this correctly. The second, just blindly keeps reading. It works well because
// it is assumed that the user will do a reset between loading and doing 
//other things. Or we could give a timeout. Anyway, work is still to be done
//here.
    // te.readTLE();
      te.echoWrite();
    }
  }
  delay(100);
}
