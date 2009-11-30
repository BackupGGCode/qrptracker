#include <Wire.h>
#include <TleStoreCallback.h>

#define EEPROM_ADDR 0x50           // I2C Buss address of 24LC256 256K EEPROM

uint8_t read(int address)
{
	return i2c_eeprom_read_byte(EEPROM_ADDR, address);
}

void write(int address, uint8_t value)
{

	 i2c_eeprom_write_byte(EEPROM_ADDR,address,value);
}



readCallback in = &read;
writeCallback out = &write;
TleStoreCallback te(in, out);

void setup() {
  Wire.begin(); 
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

byte i2c_eeprom_read_byte( int deviceaddress, unsigned int eeaddress ) {
  byte rdata = 0xFF;
  Wire.beginTransmission(deviceaddress);
  Wire.send((int)(eeaddress >> 8));    // Address High Byte
  Wire.send((int)(eeaddress & 0xFF));  // Address Low Byte
  Wire.endTransmission();
  Wire.requestFrom(deviceaddress,1);
  if (Wire.available()) rdata = Wire.receive();
  return rdata;
}

void i2c_eeprom_write_byte( int deviceaddress, unsigned int eeaddress, byte data ) {
  int rdata = data;
  Wire.beginTransmission(deviceaddress);
  Wire.send((int)(eeaddress >> 8));    // Address High Byte
  Wire.send((int)(eeaddress & 0xFF));  // Address Low Byte
  Wire.send(rdata);
  Wire.endTransmission();
}