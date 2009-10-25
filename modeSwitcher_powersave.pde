#include <avr/power.h>
#include <avr/sleep.h>
#include <avr/wdt.h>

#include <Ansiterm.h>

#include <DateTime.h>

#include <Plan13.h>
#include <TleEEPROM.h>
#define X1  0
#define Y1 1
#define X2 2
#define Y2 3

#define ONEPPM 1.0e-6
#define TIME_MSG_LEN  11   // time sync to PC is HEADER followed by unix time_t as ten ascii digits
#define TIME_HEADER  '@'   // Header tag for serial time sync message
#define DEBUG true
#define QRP   false
Plan13 p13;
TleEEPROM te = TleEEPROM();
Ansiterm ansi;
int sleepStatus = 0; 

//This would be replaced by an EEPROM-reading and writing routine       
int rectangles[][4] = {
  //Northern polar region
  //lat / long
  {65,0,
  //small, then large
  90,360},
  //Southern polar region
  {-90,0,
  -55,360},
  //Atlantic Sea between SA and Africa
  {-55,329,
  -34,350},
  //South Pacific
  {-55,200,
  0,250},
 // South Indian Sea
  {-55,47,
  -35,94}
  };
  int numberOfRects = 5;
  
   
 ISR(WDT_vect) {}
 
  void powerSaveSetup() {
  power_spi_disable();
  power_twi_disable();
  MCUSR &= ~(1<<WDRF);
  cli();
  WDTCSR |= (1<<WDCE) | (1<<WDE);
  WDTCSR = WDTO_2S;
  WDTCSR |= bit(WDIE);
  sei(); 
  }
  
  void setup() {
 
    pinMode(13, OUTPUT); 
    Serial.begin(57600);
    if (QRP) {
       powerSaveSetup();
    }
    initTime();
     
    //these shouldnt matter
    p13.setFrequency(435300000, 1459200000);//AO-51  frequency
    p13.setLocation(-64.375, 45.8958); // Sackville, NB

    
  }
  void loop() {
    if (DateTime.available()) {
      readElements(6);//this has to be here because the numbers get destroyed 
    p13.setTime(DateTime.Year+1900, DateTime.Month+1, DateTime.Day, DateTime.Hour, DateTime.Minute, DateTime.Second); 
    if (DEBUG) {reportTime();}
    p13.initSat();
    p13.satvec();
    p13.rangevec(); 
    Serial.print("Lat: ");
    Serial.println(p13.SLAT);
    Serial.print("Long: ");
    Serial.println(p13.SLON);
    if (inRects(p13.SLAT,p13.SLON)) {
      Serial.print("H");
      digitalWrite(13,HIGH);
    }
    else {digitalWrite(13,LOW);}
    if (QRP) {delay(3);
      byte prrSave = PRR, adcsraSave = ADCSRA;
     ADCSRA &= ~ bit(ADEN);
     PRR &= ~ bit(PRADC);
     set_sleep_mode(SLEEP_MODE_PWR_DOWN);
     sleep_mode();
     PRR = prrSave;
     ADCSRA = adcsraSave;
    } 
    else {
      delay(2000);
    }
  }
  }
  
  void reportTime() {
      Serial.print(DateTime.Hour,DEC);
  Serial.print(DateTime.Minute);
  Serial.print(DateTime.Second);
  Serial.print(" ");

  Serial.print(DateTime.Day,DEC); 
  Serial.print(", ");
  Serial.println(DateTime.Year+1900,DEC);
  }
  
    struct tleStruct readElements(int x)//order in the array above
{

     struct tleStruct s = te.getTle(x);

        p13.RV    =  s.RV;
        p13.YE    = s.YE;
        p13.TE    = s.TE;
        p13.IN    = s.IN;
        p13.RA    = s.RA;
        p13.EC    = s.EC;
        p13.WP    = s.WP;
        p13.MA    = s.MA;
        p13.MM    = s.MM;
        p13.M2    = s.M2;
        if (DEBUG) {
          Serial.println(s.name);
        Serial.print("RV: ");
        Serial.println( p13.RV);
        Serial.print("YE: ");
        Serial.println(p13.YE);
        Serial.print("TE: ");
        Serial.println(p13.TE);
        Serial.print("IN: ");
        Serial.println(p13.IN);
        Serial.print("RA: ");
        Serial.println(p13.RA);
        Serial.print("EC: ");
        Serial.println(p13.EC);
        Serial.print("WP: ");
        Serial.println(p13.WP);
        Serial.print("MA: ");
        Serial.println(p13.MA);
        Serial.print("MM: ");
        Serial.println(p13.MM);
        Serial.print("M2: ");
        Serial.println(p13.M2);
        Serial.println();
        }
        return s;
}

  boolean inRects(int lat, int lon) {
    for (int x = 0; x < numberOfRects; x++) {
        Serial.print("Lat bounds: ");
        Serial.print(rectangles[x][X1]);
        Serial.print(" ");
        Serial.println(rectangles[x][X2]);
                Serial.print("Long bounds: ");
        Serial.print(rectangles[x][Y1]);
        Serial.print(" ");
        Serial.println(rectangles[x][Y2]);
        Serial.println("###");
      if (lat > (float) rectangles[x][X1] && lat < (float) rectangles[x][X2] 
        && lon > (float) rectangles[x][Y1] && lon < (float) rectangles[x][Y2]) {
          Serial.print("INSIDE");
          return true;
          
        } 
    }
    // if we get through to here, then none match
    return false;
  }
  
  
  void initTime() {
  Serial.print("Enter @Seconds since Jan 1, 1970: (unix command 'date +%s'):");
  if (getNumbersFromSerial() == false) {
    Serial.println("error");
    delay(500);
    initTime();
  }

}

boolean getNumbersFromSerial() {
 while(Serial.available() <  TIME_MSG_LEN ){ ;} // time message consists of a header and ten ascii digits
    if( Serial.read() == TIME_HEADER ) { 
      Serial.print("good");      
      time_t pctime = 0;
      for(int i=0; i < TIME_MSG_LEN -1; i++){   
        char c= Serial.read();
Serial.print(c);        
        if( c >= '0' && c <= '9'){   
          pctime = (10 * pctime) + (c - '0') ; // convert digits to a number    
        }
      }   
      DateTime.sync(pctime);   // Sync Arduino clock to the time received on the serial port
      Serial.print("syncd");
      return true;   // return true if time message received on the serial port
    }  
    return false;  //if no message return false
  }
  
  double getElement(char *gstr, int gstart, int gstop)
{
  double retval;
  int    k, glength;
  char   gestr[80];

  glength = gstop - gstart + 1;

  for (k = 0; k <= glength; k++)
  {
     gestr[k] = gstr[gstart+k-1];
  }

  gestr[glength] = '\0';
  retval = atof(gestr);
  return(retval);
}
  
  void getTime() {
  ansi.eraseScreen();
  ansi.boldOn();
  ansi.xy(0,0);
  Serial.print("Enter @Seconds since Jan 1, 1970: (unix command 'date +%s'):");
  if (getNumbersFromSerial() == false) {
    ansi.eraseLine();
    ansi.xy(0,0);
    Serial.println("error");
    DateTime.sync(1254163584);
  }

}
