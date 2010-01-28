

/*User-alterable defines, intended to customize the satpack. Not all combinations will work with all
 architectures. Specifically, the Atmega328  does not allow the use of USE_GPS or USE_GPS_TIME
 */

//DEBUGME true will cause the Satpack program to output information on the serial line indicating 
//the current tracked satellite, its az/el and uplink and downlink frequencies
#define DEBUGME true
//USE_GPS true indicates that a GPS unit will be used to determine the location of the tracking unit
#define USE_GPS false
//USE_GPS_TIME indicates that a GPS unit will be used to determine the current time
#define USE_GPS_TIME false
//I2C_EEPROM true indicates that an external EEPROM on the I2C line 
//is being used to store the TLEs and Modelines
//Requires about 180 more bytes than using the internal EEPROM
#define I2C_EEPROM false
#define BOUNCE_DURATION 20   // define an appropriate bounce time in ms for your switches
#define GREEN_LED_PIN 4
#define RED_LED_PIN   6
#define BIRD_LOCATION_TIMEOUT 60000
#define WRITE_DELAY 50
//the minimum elevation that triggers tracking. Degrees integer.
#define MIN_ELEVATION 0.0
#define TURN_OFF_RIG false
#define FM_DELTA_TRIGGER 60 // Difference in 10Hz that triggers a freq. update
#define LINEAR_DELTA_TRIGGER 25 // difference in 10Hz that triggers a freq. update
#define RIG_SERIAL_SPEED 9600
#define LOOP_DELAY 200
/*Below are defined pins that are peculiar to specific architectures
 */
#if defined(__AVR_ATmega644P__) || defined(__AVR_ATmega644__) // compiled as ATMega644
//Atmega644 Version
#define SPEAKER_PIN 12
#define MODE_BUTTON_PIN 2 // on digital pin 2, physical pin 3
#define TRANSMIT_INTERRUPT 1 // actually digital pin 3, physical pin 17
// this is also TXD1. I'm not sure if we can split its purpose in this way, 
// but I'm thinking we could use only RXD1 to receive the GPS.
#else  // if ATMega328
#define SPEAKER_PIN 5
#define MODE_BUTTON_PIN 2 //actually digital pin 2, physical pin 4
#define XMIT_BUTTON_PIN 3 // not used right now
#define TRANSMIT_INTERRUPT 1 // actually digital pin 3, physical pin 5
#endif
// in both cases, the Rig is on a soft serial line using digital pins 5 and 6
// this is hard coded into the FT-817 library.
// 644P: physical 5 and 6
// 328:  physical 16 and 17

#define TLE_VERSION_NUMBER 0
//Universal includes
#include <CW.h>
#include <FT817.h>
#include <Plan13.h>
#include <TleStoreCallback.h>


//Conditional Includes
#if USE_GPS
#include <NewSoftSerial.h>
#include <TinyGPS.h>
#endif
#if !USE_GPS_TIME
#include <DS1307.h>
#endif 
#if I2C_EEPROM or !USE_GPS_TIME
#include <Wire.h>
#endif

//For some reason, removing this library causes functions not to be found
//So we keep it in place if DEBUGME is running, or not.
//#if DEBUGME
#include <Ansiterm.h>
Ansiterm ansi;
//#endif

//Set up the means of reading and writing to either internal EEPROM 
// or I2CEEPROM
#if I2C_EEPROM
#define I2C_EEPROM_ADDR 0x50           // I2C Buss address of 24LC256 256K EEPROM
void write(int address, uint8_t value)
{
  i2c_eeprom_write_byte(I2C_EEPROM_ADDR, address, value);
}

uint8_t read(int address)
{
  return i2c_eeprom_read_byte(I2C_EEPROM_ADDR, address);
}
#else
#include <avr/eeprom.h>
void write(int address, uint8_t value)
{
  eeprom_write_byte((unsigned char *) address, value);
}

uint8_t read(int address)
{
  return eeprom_read_byte((unsigned char *) address);
}
#endif
readCallback in = &read;
writeCallback out = &write;
TleStoreCallback te(in, out, WRITE_DELAY);

#if USE_GPS
TinyGPS gps;
NewSoftSerial nss(5,-1);
#endif

unsigned long bounceTime=0; // variable to hold ms count to debounce a pressed switch
unsigned long birdLocationTimeout = 0;

Plan13 p13;
FT817 rig;
tleStruct currentTle;
modelineStruct currentModeline;
unsigned int currentSatAddress;
byte numberOfModelines;
int freqDiff;
byte buttonCounter = 0;

void doOn() {
  analogWrite(SPEAKER_PIN, 300);
}
void doOff() {
  analogWrite(SPEAKER_PIN,0);
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
CW cw(onPointer, offPointer, byte(45));

byte modelineNumber = 0;
byte currentBird = 255;
boolean activeTracking = false;
unsigned long previousUplinkFreq = 0;
void setup() {

#if USE_GPS
  nss.begin(9600);
#endif
#if !USE_GPS_TIME
  Wire.begin(); 
#endif
  pinMode(GREEN_LED_PIN, OUTPUT); 
  pinMode(RED_LED_PIN, OUTPUT);
  //pinMode(SPEAKER_PIN, OUTPUT);
  pinMode(MODE_BUTTON_PIN, INPUT);
  digitalWrite(MODE_BUTTON_PIN, HIGH); // turn on pullup resistor

  digitalWrite(GREEN_LED_PIN, false);
  Serial.begin(115200);
  tryToGetTles();
  rig.begin(RIG_SERIAL_SPEED);//4,5 rx,tx
  //instead of this, use EEPROM header.
#if DEBUGME
  ansi.xy(0,11);
  Serial.print(te.getLatitude());
  Serial.print("N ");
  Serial.print(te.getLongitude());
  Serial.print("E ");
  Serial.print(te.getAltitude());
  Serial.print("m");
#endif
#if !USE_GPS
p13.setLocation(-64.375, 45.8958, 60); // Sackville, NB
//  p13.setLocation(te.getLongitude(), te.getLatitude(), te.getAltitude()); 
#endif
  te.readHeader();
#if !DEBUGME
  if (te.getVersion() != TLE_VERSION_NUMBER || te.numberOfTles == 0) {
    cw.signalChars("?? tles ??");
  }
#endif
}

void loop() {  
  digitalWrite(GREEN_LED_PIN, activeTracking);//led tells us if 
  //we are tracking
  unsigned long foo = millis();
  boolean freqShift = false;
  boolean changeModeline = false;
  
  if (digitalRead(MODE_BUTTON_PIN) == LOW) {//signal low
    if (activeTracking) {
      cw.signalChar('r');
      changeModeline = true;
      modelineNumber++;
    }
    else {
      selfTest();
    }
  }
  
  if (modelineNumber >= numberOfModelines) {
    //we've paged through all the modes of this bird
    //so we'll go to the next one, and start with its first mode
    activeTracking = false;

  }
  //increment the birds if we are not actively tracking or we are scanning
  // unsigned int currentSatAddress;
  if (!activeTracking) {
    currentBird++; // we started at -1 so we should be good. Mind you, turning this into a char would be good.
    if (currentBird >= te.numberOfTles) {
      currentBird = 0;
    }
    modelineNumber = 0;
    changeModeline = true;
    currentSatAddress = te.getSatAddress(currentBird);
    currentTle = te.getTle(currentBird);
    numberOfModelines = te.countModelinesForTle(currentSatAddress);
#if !DEBUGME
    Serial.print(currentTle.name);
#endif
#if DEBUGME
    ansi.setForegroundColor(WHITE);
    ansi.xy(1,1);
    Serial.print(currentTle.name);
    Serial.print(" (");
    Serial.print(currentBird + 1);
    Serial.print("/");
    Serial.print(te.numberOfTles);
    Serial.print(")  ");
    //ansi.setForegroundColor(WHITE);
#endif
  }//end if !activeTracking
  ansi.xy(1,2);
  if (changeModeline) {
    currentModeline = te.getModelineForAddress(te.getModelineStart(currentSatAddress, modelineNumber));
    if (activeTracking) {
      cw.signalChars(currentModeline.modeName);
    }
  }
  else {
    Serial.print("       ");
  }
  //everyone needs us to get time and place
#if USE_GPS 
  // need a timeout here so we don't doo this all the time
  assignLocationToP13FromGPS();
#endif
#if USE_GPS_TIME
  assignTimeToP13FromGPS();
#else
  assignTimeToP13();
#endif
  assignTleStructToP13(currentTle);
#if DEBUGME
  ansi.xy(1,8);
  Serial.print("Diff ");
  Serial.print(freqDiff);
  Serial.print("    ");
#endif
  //only allow hand tuning if not FM mode
  if (!changeModeline && activeTracking && currentModeline.dlMode != FM && currentModeline.dlMode != FMN) {
    freqDiff =   rig.getFreqMode() - (p13.rxOutLong +5)/10;
    if (freqDiff != 0) {
      freqShift = true;
#if DEBUGME
      ansi.xy(1,9);
      ansi.xy(1,8);
      Serial.print("  First Diff: ");
      Serial.print(freqDiff);
      Serial.print("            ");
#endif
      currentModeline.dlLong += freqDiff*10;
      if (currentModeline.ulLong != 0) {
        if (currentModeline.polarity == NOR) {
          currentModeline.ulLong += (freqDiff);
        }
        else if (currentModeline.polarity == REV) {
          currentModeline.ulLong -= freqDiff;
        }
      }
      freqDiff = 0; 
    }
  }// end check that this isn't FM

#if DEBUGME
  // ansi.xy(1,2);
  // Serial.print("dlLong: ");
  // Serial.print(currentModeline.dlLong);
#endif
  p13.setFrequency(currentModeline.dlLong, currentModeline.ulLong);
  p13.calculate();
#if DEBUGME
  ansi.xy(1,10);
  sayTime();
  ansi.xy(1,5);
  Serial.print("AZ: ");
  Serial.print(p13.AZ);
  Serial.print(" EL: ");
  Serial.println(p13.EL);
  ansi.xy(1,6);
  Serial.print("Rx ");
  Serial.println(p13.rxOutLong);
  Serial.print(" Tx: ");
  if ( currentModeline.ulLong != 0) {
    Serial.println(p13.txOutLong);
  }
  else {
    //ansi.setForegroundColor(RED);
    Serial.println("n/a          ");
  }
#endif
  if (p13.EL > MIN_ELEVATION) {//this bird is above the horizon
#if DEBUGME
    ansi.setForegroundColor(GREEN);
    ansi.xy(21,1);
    Serial.print("    ");
    ansi.xy(24,1);
    Serial.print(currentModeline.modeName);
    Serial.print(" (");
    Serial.print((int)modelineNumber + 1);
    Serial.print("/");
    Serial.print((int)numberOfModelines);
    Serial.print(")  ");
    ansi.xy(21,1);
    Serial.print("UP");
    ansi.setForegroundColor(WHITE);
#endif 
    if (!activeTracking || changeModeline) {
      //bird is up *and* we are not actively tracking, so this is a new bird for us
      previousUplinkFreq = 0;
      if (TURN_OFF_RIG) {
        rig.on();
        rig.on();
      }//end TURN_OFF_RIG
      setMode(rig,currentModeline.dlMode);
      if ( currentModeline.ulLong > 0) {// not a listen-only bird
        rig.setSplitModeOn();
        rig.switchVFO();
        setMode(rig,currentModeline.ulMode);
        if (currentModeline.tone > 0 && currentModeline.ulMode == FM) {
           rig.setCTCSSEncoderOn();
           rig.setCTCSSFreq(currentModeline.tone);
        }
        rig.switchVFO();
      }
      else {// this is a listen-only bird
        rig.setSplitModeOff();
      }

    }//end if !activeTracking
    if (!rig.txState2() && !freqShift) {  // we are receiving and the sat is up      should we also check for !freqShift?
      long currentDownlinkFreq = (p13.rxOutLong + 5) / 10;
#if DEBUGME
      ansi.xy(1,11);
      //move in case there is an error message
#endif
      rig.setFreqTest(currentDownlinkFreq);
      long currentUplinkFreq = (p13.txOutLong + 5)/ 10;
      long delta = abs(currentUplinkFreq - previousUplinkFreq);
      boolean match = (
      ((currentModeline.ulMode == FMN || currentModeline.ulMode == PKT || currentModeline.ulMode == FM) && delta > FM_DELTA_TRIGGER) || 
        ((currentModeline.ulMode == USB || currentModeline.ulMode == LSB || currentModeline.ulMode == CWMODE) && delta > LINEAR_DELTA_TRIGGER)
        );
      if ( currentModeline.ulLong > 0 && match) {//this is a transmitting bird and we fit the conditions above

#if DEBUGME
        ansi.xy(1,4);
        Serial.print("T"); // not a listen-only bird
        ansi.xy(1,11);
#endif
        rig.switchVFO();//go to the transmit side
#if DEBUGME
        ansi.xy(1,11);
        //move in case there is an error message
#endif       
        rig.setFreqTest(currentUplinkFreq);
        rig.switchVFO();//go to the receive side again
#if DEBUGME
        ansi.xy(1,4);
        Serial.print(" ");
        ansi.xy(1,11);
#endif
        previousUplinkFreq = currentUplinkFreq;
        //store this so that we know how much things have changed, and
        //will only alter the uplink frequency when beyond our tolerance
      }
    }//end !txState2



    if (!activeTracking) {// we do this at the end so
      //that announcing doesn't take up tracking time.
      activeTracking = true;
      freqDiff = 0;
      digitalWrite(GREEN_LED_PIN, activeTracking);
      announceBirdCW();
    }
    else if ( millis() > birdLocationTimeout + BIRD_LOCATION_TIMEOUT) {
      announceBirdCW();
    }
  }//end if el > 0 
  else{//bird is below horizon
#if DEBUGME
    ansi.xy(21,1);
    ansi.setForegroundColor(RED);
    Serial.print("D     ");
    ansi.setForegroundColor(WHITE);
#endif
    if(activeTracking) {
      activeTracking = false;
      if (TURN_OFF_RIG) {
        rig.off();
      }
      cw.signalChars(currentTle.name);
      cw.signalChar(' ');
      cw.signalChars("qrt");
      //   Not sure if we can afford this

        if (currentModeline.dlLong > 0) {
        

        setMode(rig,FM);
        rig.switchVFO();
        setMode(rig,FM);
        rig.setCTCSSOff();
        rig.switchVFO();
        rig.setSplitModeOff();
      }

    }
  }
#if DEBUGME
  //print out the delay for each calculation loop
  ansi.xy(1,12);
  Serial.print(millis() - foo);
  Serial.print("   ");
#endif
  delay(LOOP_DELAY);//opportunity to tune here
}//end loop()


void announceBirdCW() {
  cw.signalChars(currentTle.name);
  signalBirdPosition(p13.AZ, p13.EL);
  birdLocationTimeout = millis();
}


void signalBirdPosition(float az, float el) {
  char elChar;
  char *azString;
  int elInt = (int)el;
  if (elInt < 0) { 
    return;
  }
  else if (elInt < 10) { 
    elChar = 'L';
  }
  else if (elInt >= 10 && elInt <= 45) { 
    elChar = 'M';
  }
  else if (elInt > 45) {
    elChar = 'H';
  }  
  unsigned int azInt = az * 100;
  ansi.xy(1,2);
  Serial.print(az);
  Serial.print("  ");
  Serial.print(azInt);
  if (0 <= azInt && azInt < 1125) { 
    azString = "N";
  }
  else if (1125 <= azInt && azInt < 3375)  {
    azString = "NNE";
  }
  else if (3375 <= azInt && azInt < 5625) {
    azString = "NE";
  }
  else if (5625 <= azInt && azInt < 7875) {
    azString = "ENE";
  }
  else if (7875 <= azInt && azInt < 10125) {
    azString = "E";
  }
  else if (10125 <= azInt && azInt < 12375) {
    azString = "ESE";
  }
  else if(12375 <= azInt && azInt < 14625) {
    azString = "SE";
  } 
  else if(14625 <= azInt && azInt < 16875) {
    azString = "SSE";
  }
  else if (16875 <= azInt && azInt < 19125) {
    azString = "S";
  }
  else if (19125 <= azInt && azInt < 21375) {
    azString = "SSW";
  }
  else if (21375 <= azInt && azInt < 23625) {
    azString = "SW";
  }
  else if (23625 <= azInt && azInt < 25825) {
    azString = "WSW";
  }
  else if (25825 <= azInt && azInt < 28125) {
    azString = "W";
  }
  else if (28125 <= azInt && azInt < 30375) {
    azString = "WNW";
  }
  else if (30375 <= azInt && azInt < 32625) {
    azString = "NW";
  }
  else if (32625 <= azInt && azInt < 34875) {
    azString = "NNW";
  }
  else if (34875 <= azInt && azInt < 0) {
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
      rig.setMode(FT817_MODE_USB);
      break;
    }
  case LSB: 
    {
      rig.setMode(FT817_MODE_LSB);
      break;
    }
  case PKT:
    {
      rig.setMode(FT817_MODE_PKT);
      break;
    }
  }
}

#if USE_GPS
/* GPS Routines */
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

bool feedgps()
{
  while (nss.available())
  {
    if (gps.encode(nss.read()))
      return true;
  }
  return false;
}
#endif

void assignTleStructToP13(tleStruct tle) {
  p13.setElements(tle.YE, tle.TE, tle.IN, tle.RA, tle.EC, tle.WP, tle.MA, tle.MM, tle.M2, tle.RV, 0);
  //is the last value, ALON, wrong?
}

#if USE_GPS_TIME
void assignTimeToP13FromGPS() {
  int year;
  byte month, day, hour, minute, second, hundredths;
  unsigned long fix_age;
  //check for bad fixage here.
  gps.crack_datetime(&year, &month, &day,
  &hour, &minute, &second, &hundredths, &fix_age);
  p13.setTime(year, int(month), int(day), int(hour), int(minute), int(second));
}
#else
void assignTimeToP13() {
  int year = RTC.get(DS1307_YR,true);
  /*
  if (year < 2009 || year > 2015) {// only good until end of 2015!
   cw.signalChars("Time??");
   }
   */
  p13.setTime(year, RTC.get(DS1307_MTH,false), RTC.get(DS1307_DATE,true), RTC.get(DS1307_HR,true), RTC.get(DS1307_MIN,true), RTC.get(DS1307_SEC,true)); 
}
#endif

#if I2C_EEPROM
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
#endif

void selfTest() {
  // if you're running the console, you don't need this,
  // and you'll need the programming space
//#if !DEBUGME
  //Is the clock working?
  cw.signalChars("Time");
  if (RTC.get(DS1307_YR,true) > 2009) {
    cw.signalChars(" ok");
  }
  else {
    cw.signalChars("??");
  }
  morseSpace();
  //How many tles do we have?
  char str[3];
  cw.signalChars(itoa(te.numberOfTles, str, 10));
  //which satellites are there?
  cw.signalChars(" Sats ");
  for (int x = 0; x < te.numberOfTles; x++) {
    cw.signalChars(te.getTle(x).name);
    morseSpace();
  }
//#endif
}

void morseSpace() {
  cw.signalChars("  ");
}

void sayTime() {
#if !USE_GPS_TIME
  /*
  Serial.print(RTC.get(DS1307_YR,true));
   Serial.print(" ");
   Serial.print(RTC.get(DS1307_MTH,false));
   Serial.print(" ");
   Serial.print(RTC.get(DS1307_DATE,true));
   Serial.print(" ");
   */
  Serial.print(RTC.get(DS1307_HR,true));
  Serial.print(":");
  Serial.print(RTC.get(DS1307_MIN,true));
  Serial.print(":");
  Serial.println(RTC.get(DS1307_SEC,true));
#endif
}

void tryToGetTles() {
  //  cw.signalChars("TLE?");
  te.greeting();

  unsigned long serialTimeout = millis();
  boolean pin = false;
  while ((Serial.available() < 1) && ((serialTimeout + 5000) > millis()))
  {
    pin = !pin;
    digitalWrite(GREEN_LED_PIN,pin);
    digitalWrite(RED_LED_PIN,!pin);
    delay(1000);
  }
  // cw.signalChars(".");
  if (Serial.read() == 'R') {
    setTime();
    //we need something in here to negotiate if the burner
    //plans to give TLEs
   // te.echoWrite();
  }
  // cw.signalChars("qrt");
}

boolean setTime() {
  boolean pin = false;//9:55:12 am on Christmas Day, 2009 //09122509065512
  while (Serial.available() < 14) {
    pin = !pin;
    digitalWrite(GREEN_LED_PIN, pin);
    delay(100);
    Serial.print('T');
    Serial.print(Serial.available());
  }
  readTwo(DS1307_YR);
  readTwo(DS1307_MTH);
  readTwo(DS1307_DATE);
  readTwo(DS1307_DOW);
  readTwo(DS1307_HR);
  readTwo(DS1307_MIN);
  readTwo(DS1307_SEC);
  //return indication that the setting was successful
  Serial.print('T');
}

/* Routines for reading the time values off the serial line.
   the general atoi library takes up more memory because it makes fewer 
   assumptions
*/

void readTwo(int value) {
  RTC.set(value, atoi_tens(Serial.read()) + atoi_ones(Serial.read()));
}

char atoi_ones(char in) {
  return in - 48;
}

char atoi_tens(char in) {
  return atoi_ones(in) * 10;
}






