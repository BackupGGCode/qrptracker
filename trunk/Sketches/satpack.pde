#include <CW.h>
#include <Tone.h>
#include <NewSoftSerial.h>
#include <TinyGPS.h>
#include <FT817.h>

#include <DS1307.h>

#include <Plan13.h>

#include <Wire.h>

#include <TleStoreCallback.h>
#include <avr/eeprom.h>
#define BOUNCE_DURATION 20   // define an appropriate bounce time in ms for your switches

volatile unsigned long bounceTime=0; // variable to hold ms count to debounce a pressed switch

#define SPEAKER_PIN 11
#define LED_PIN 13
#define EEPROM_ADDR 0x50           // I2C Buss address of 24LC256 256K EEPROM
#define DEBUGME true
#define BIRD_LOCATION_TIMEOUT 60000
#define WRITE_DELAY 50
FT817 rig;

Tone notePlayer;
void doOn() {
  notePlayer.play(NOTE_G4);
}
void doOff() {
  notePlayer.stop();
}

/* If the naming convention used above is retained, these pointers to the
 on and off functions can be kept as-is.
 */
signalFunction onPointer = &doOn;
signalFunction offPointer = &doOff;

/* Declaring the CW object, with its two on and off functions, as well as
 the initial speed of the code in wpm. Note that the speed is declared in a
 byte, not an int
 */
CW cw(onPointer, offPointer, byte(35));

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
TleStoreCallback te(in, out, WRITE_DELAY);

Plan13 p13;
TinyGPS gps;
NewSoftSerial nss(5,-1);
volatile int currentBird;
boolean changedBird = true;
boolean trackingInProgress = false;
unsigned long birdLocationTimeout;
void setup() {
  //  attachInterrupt(0, buttonPush, LOW);
  nss.begin(9600);
  notePlayer.begin(SPEAKER_PIN);
  // cw.signalChars("Hi there bruce");
  Wire.begin(); 
  pinMode(13, OUTPUT); 
  Serial.begin(38400);
  tryToGetTles();
  rig.begin(9600);//2,3 rx,tx
  p13.setLocation(-64.375, 45.8958, 60); // Sackville, NB
  te.readHeader();
  if (DEBUGME) {
    Serial.print("Number of Birds: ");
    Serial.println(te.numberOfTles);
    Serial.print("Number of Modelines: ");
    Serial.println(te.numberOfModelines);
  }
}

void loop() {

  currentBird = 0;
  findNextBird();
}

void findNextBird() {
  changedBird = true;
  // if (currentBird > te.numberOfTles) {currentBird = te.numberOfTles;}
  for (int x = 0; x < te.numberOfTles; x++) {

    tleStruct currentTle = te.getTle(x);
    modelineStruct bar = te.getModelineForSatNumber(x);
    currentBird = x;
    if (DEBUGME) {
      Serial.print(x);
      Serial.println(currentTle.name);
    }
    while (testBird(currentTle, bar)) {
      delay(1000);
    }//just keep doing it

  }
}

boolean testBird(tleStruct currentTle, modelineStruct currentModeline) {
  // assignLocationToP13FromGPS();
  assignTleStructToP13(currentTle);
  assignTimeToP13();
  //assignLocationToP13FromGPS();
  if (DEBUGME) {
    Serial.print("DL: " );
    Serial.println(currentModeline.dlLong);
  }
  p13.setFrequency(currentModeline.dlLong, currentModeline.ulLong);  
  p13.calculate();
  if (DEBUGME) {
    sayTime();
    Serial.print("\tAZ: ");
    Serial.println(p13.AZ);
    Serial.print("\tEL: ");
    Serial.println(p13.EL);
    Serial.print("\tFreq. out: ");
    Serial.println(p13.rxOutLong);
    Serial.print("\tCurrent bird: ");
    Serial.println(currentBird);
  }
  delay(100);
  if (p13.EL > 0) {
    //set rig frequency
    rig.setFreqTest((p13.rxOutLong +5) / 10);
    if (changedBird) {
      Serial.println("Changed bird");
      setMode(rig,currentModeline.dlMode);
      trackingInProgress = true;
    }
    else if (trackingInProgress == true) {
      cw.signalChars(currentTle.name);
      cw.signalChars(" qrt");
      trackingInProgress = false;
    }
    if (changedBird || millis() > birdLocationTimeout + BIRD_LOCATION_TIMEOUT) {
      cw.signalChars(currentTle.name);
      signalBirdPosition(p13.AZ, p13.EL);
      birdLocationTimeout = millis();
      if (DEBUGME) {
        Serial.print("birdLocationTimeout: " );
        Serial.println(birdLocationTimeout);
        Serial.print("millis: ");
        Serial.println(millis());
      }
    }
    changedBird = false;
    return true;

  }
  else {
    changedBird = true;
    return false;
  }
}


void signalBirdPosition(float az, float el) {
  char elChar;
  char *azString;
  if (el < 0) { 
    return;
  }
  else if (el < 10) { 
    elChar = 'L';
  }
  else if (el >= 10 && el <= 45) { 
    elChar = 'M';
  }
  else if (el > 45) {
    elChar = 'H';
  }  
  if (0 <= az && az < 11.25) { 
    azString = "N";
  }
  else if (11.25 <= az && az < 33.75)  {
    azString = "NNE";
  }
  else if (33.75 <= az && az < 56.25) {
    azString = "NE";
  }
  else if (56.25 <= az && az < 78.75) {
    azString = "ENE";
  }
  else if (78.75 <= az && az < 101.25) {
    azString = "E";
  }
  else if (101.25 <= az && az < 123.75) {
    azString = "ESE";
  }
  else if(123.75 <= az && az < 146.25) {
    azString = "SE";
  } 
  else if(146.25 <= az && az < 168.75) {
    azString = "SSE";
  }
  else if (168.75 <= az && az < 191.25) {
    azString = "S";
  }
  if (0 <= az && az < 11.25) { 
    azString = "N";
  }
  else if (11.25 <= az && az < 33.75)  {
    azString = "NNE";
  }
  else if (33.75 <= az && az < 56.25) {
    azString = "NE";
  }
  else if (56.25 <= az && az < 78.75) {
    azString = "ENE";
  }
  else if (78.75 <= az && az < 101.25) {
    azString = "E";
  }
  else if (101.25 <= az && az < 123.75) {
    azString = "ESE";
  }
  else if(123.75 <= az && az < 146.25) {
    azString = "SE";
  } 
  else if(146.25 <= az && az < 168.75) {
    azString = "SSE";
  }
  else if (168.75 <= az && az < 191.25) {
    azString = "S";
  }
  else if (191.25 <= az && az < 213.75) {
    azString = "SSW";
  }
  else if (213.75 <= az && az < 236.25) {
    azString = "SW";
  }
  else if (236.25 <= az && az < 258.25) {
    azString = "WSW";
  }
  else if (258.25 <= az && az < 281.25) {
    azString = "W";
  }
  else if (281.25 <= az && az < 303.75) {
    azString = "WNW";
  }
  else if (303.75 <= az && az < 326.25) {
    azString = "NW";
  }
  else if (326.25 <= az && az < 348.75) {
    azString = "NNW";
  }
  else if (348.75 <= az && az < 0) {
    azString = "N";
  }
  cw.signalChars(azString);
  cw.signalChars(" ");
  cw.signalChar(elChar);

}

void setMode(FT817 rig, char mode) {
  switch(mode) {
  case CWMODE: 
    {
      rig.setMode(FT817_MODE_CW);
      break;
    }
  case FM:     
    {
      rig.setMode(FT817_MODE_FM);
      break;
    }
  case USB: 
    {
      rig.setMode(FT817_MODE_FM);
      break;
    }
  }
}


void assignLocationToP13FromGPS() {
  //timeout here is an issue

  float flat, flon;
  long unsigned age;
  bool newdata = false;
  unsigned long start = millis();

  // if we go five seconds without a fix, or if we get a fix, move on
  while (newdata == false && (millis() - start < 5000))
  {
    if (feedgps())
      newdata = true;
  }
  if (newdata) {
    gps.f_get_position(&flat, &flon, &age);
    Serial.println((gps.altitude() + 50) /100);
    p13.setLocation(flon, flat, 20);// (gps.altitude + 50) / 100 );
  }
  else {
    p13.setLocation(-64.375, 45.8958, 20); // Sackville, NB
  }
}

void assignTleStructToP13(tleStruct tle) {
  p13.setElements(tle.YE, tle.TE, tle.IN, tle.RA, tle.EC, tle.WP, tle.MA, tle.MM, tle.M2, tle.RV, 0);
  //is the last value, ALON, wrong?
}

void assignTimeToP13() {
  int year = RTC.get(DS1307_YR,true);
  if (year < 2009 || year > 2015) {// only good until end of 2015!
    cw.signalChars("Time??");
  }
  p13.setTime(RTC.get(DS1307_YR,true), RTC.get(DS1307_MTH,false), RTC.get(DS1307_DATE,true), RTC.get(DS1307_HR,true), RTC.get(DS1307_MIN,true), RTC.get(DS1307_SEC,true)); 
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

/* GPS Routines */
bool feedgps()
{
  while (nss.available())
  {
    if (gps.encode(nss.read()))
      return true;
  }
  return false;
}

/* Pushbutton routines */
void buttonPush() {

  // this is the interrupt handler for button presses
  // it ignores presses that occur in intervals less then the bounce time
  if (abs(millis() - bounceTime) > BOUNCE_DURATION)
  {
    // Your code here to handle new button press …
    currentBird++;
    // findNextBird();
    bounceTime = millis();  // set whatever bounce time in ms is appropriate
  }
}

void sayTime() {
  Serial.print(RTC.get(DS1307_YR,true));
  Serial.print(" ");
  Serial.print(RTC.get(DS1307_MTH,false));
  Serial.print(" ");
  Serial.print(RTC.get(DS1307_DATE,true));
  Serial.print(" ");
  Serial.print(RTC.get(DS1307_HR,true));
  Serial.print(":");
  Serial.print(RTC.get(DS1307_MIN,true));
  Serial.print(":");
  Serial.println(RTC.get(DS1307_SEC,true));
}

void tryToGetTles() {
  //  cw.signalChars("TLE?");
  te.greeting();
  unsigned long serialTimeout = millis();
  while ((Serial.available() < 1) && ((serialTimeout + 10000) > millis()))
  {
    ;
  }
  // cw.signalChars(".");
  if (Serial.read() == 'R') {
    te.echoWrite();
  }
  // cw.signalChars("qrt");
}

