
#include <DateTimeStrings.h>
#include <Plan13.h>
#include <DateTime.h>
#include <avr/power.h>
#include <avr/sleep.h>
#include <TleStoreCallback.h> //oddly, this has to come after plan13.h

#include <Ansiterm.h>
#define TIME_MSG_LEN  11   // time sync to PC is HEADER followed by unix time_t as ten ascii digits
#define TIME_HEADER  '@'   // Header tag for serial time sync message
#define SATNAME_POS
#define NAME_POS 1
#define ONEPPM 1.0e-6
#define SAT_INFO_START_ROW 7
#define AZ_POS 10
#define EL_POS 20
#define LAT_POS 30
#define LON_POS 40
//#define RANGE_POS 50
#define RX_POS 50
#define TX_POS 60
#define DEBUG false
#define NUMBER_OF_TLES 7
#define TITLE_OFFSET 3

#define WRITE_DELAY 50
boolean dateTimeStart = false;
Ansiterm ansi;
Plan13 p13;
long timing;
#include <avr/eeprom.h>
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
TleStoreCallback te = TleStoreCallback(in, out, WRITE_DELAY);
 
 //this was meant as a substitute for delay(), but it appears to slip time a bit.
 //For instance, when I used rest(200) at the end of each loop, after 9 h it had 
 //lost about 25 seconds.
 void rest(int forHowLong) {
  long limit = millis() + forHowLong; 
   while (millis() < limit) {
     set_sleep_mode(SLEEP_MODE_IDLE);
     sleep_enable();

     sleep_mode();
   }
 }

void setup() {
    Serial.begin(115200);
  if (te.readHeader() == false) {
   Serial.println("Bad satellite elements in EEPROM.");
   Serial.println("Please load them in with the program.");
   exit(0);
  } // find out how many tles and modelines are in the eeprom
  power_adc_disable(); //7.28 - 7.33 mA
  power_spi_disable();
  power_twi_disable();// with all of these, around 6.3 mA
   // power_timer2_disable();// seems to make things worse!

   p13.setLocation(-64.375, 45.8958, 60); // Sackville, NB
}

void loop() {
  if (DateTime.available()) {
    if (dateTimeStart) {
      
      layout();
      dateTimeStart = false;
    }
    if (DEBUG) {
      Serial.println(te.numberOfTles);
    }
    for (int x = 0; x < te.numberOfTles; x++) {
      timing = millis();
    tleStruct s = readElements(x);
    modelineStruct m = te.getModelineForAddress(te.getModelineStart(te.getSatAddress((byte) x), 0));//we pass the number of the satellite
    p13.setFrequency(m.dlLong, m.ulLong);
    p13.setTime(DateTime.Year+1900, DateTime.Month+1, DateTime.Day, DateTime.Hour, DateTime.Minute, DateTime.Second); 
    
    p13.initSat();
    p13.satvec();
    p13.rangevec(); 
    timing = millis() - timing;
    displayTime();
    displaySatInfo(SAT_INFO_START_ROW + x, s.name);//on row 3
    
  //  rest(500);
  }
  }
  else {
    getTime();
    dateTimeStart = true;
  }
 // rest(200);
  delay(200);
}
void layout() {
  ansi.setBackgroundColor(RED);
  ansi.fill(0,0,80,4);
  ansi.setForegroundColor(WHITE);
  ansi.xy(15,2);
  ansi.boldOn();
  Serial.print("PRED13T: Arduino Plan13 Satellite Tracking Demo");
  ansi.boldOff();
  ansi.setBackgroundColor(BLUE);
  ansi.fill(0,6,80,25);
  ansi.setBackgroundColor(WHITE);
  ansi.setForegroundColor(WHITE);
  ansi.fill(0,5,80,5);
  int title_row = 5;
  ansi.setForegroundColor(BLUE);
  ansi.setBackgroundColor(WHITE);
  ansi.xy(NAME_POS,title_row);
  Serial.print("Sat.");
  ansi.xy(AZ_POS + TITLE_OFFSET ,title_row);
  Serial.print("AZ");
  ansi.xy(EL_POS + TITLE_OFFSET,title_row);
  Serial.print("El");
  ansi.xy(LAT_POS + TITLE_OFFSET,title_row);
  Serial.print("Lat");
  ansi.xy(LON_POS + TITLE_OFFSET,title_row);
  Serial.print("Lon");
 
  ansi.xy(RX_POS + TITLE_OFFSET,title_row);
  Serial.print("RX");
  ansi.xy(TX_POS + TITLE_OFFSET,title_row);
  Serial.print("TX");

}
  
void displaySatInfo(int row, char * name) {
 // float rx = p13.rxFrequency * (1.0 - p13.RR / 299792.0);
 // float tx = p13.txFrequency  * (1.0 + p13.RR / 299792.0);
    ansi.setForegroundColor(WHITE);
  ansi.setBackgroundColor(BLUE);
  if (p13.EL > 0.0) { ansi.boldOn();}
  else {ansi.boldOff();}
  ansi.xy(NAME_POS,row);
  Serial.print(name);
  ansi.xy(AZ_POS,row);
  formatPrint(p13.AZ);
  Serial.print(p13.AZ);
  ansi.xy(EL_POS,row);
  formatPrint(p13.EL);
  Serial.print(p13.EL);
  ansi.xy(LAT_POS,row);
  formatPrint(p13.SLAT);
  Serial.print(p13.SLAT);
  ansi.xy(LON_POS,row);
  formatPrint(p13.SLON);
  Serial.print(p13.SLON);
  ansi.xy(RX_POS,row);
  Serial.print(p13.rxOutLong);
  ansi.xy(TX_POS,row);
  Serial.print(p13.txOutLong);
  ansi.boldOff();
}
void formatPrint(float value) {
  if (value < -10.0) {
    return;
  }
  if (value < 0) {
    Serial.print(" ");
    return;
  }
  if (value < 10.0) {
    Serial.print("  ");
    return;
  }
  
  if (value < 100.0) {
    Serial.print(" ");
    return;
  }
  return;
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


  struct modelineStruct getModeline(int x) {
    
    
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


void displayTime() {
  ansi.setBackgroundColor(RED);
  ansi.setForegroundColor(WHITE);
  ansi.boldOn();
  ansi.xy(20,3);
  Serial.print(DateTime.Hour,DEC);
  printDigits(DateTime.Minute);
  printDigits(DateTime.Second);
  Serial.print(" ");
  Serial.print(DateTimeStrings.dayStr(DateTime.DayofWeek));
  Serial.print(" ");
  Serial.print(DateTimeStrings.monthStr(DateTime.Month));
  Serial.print(" ");
  Serial.print(DateTime.Day,DEC); 
  Serial.print(", ");
  Serial.print(DateTime.Year+1900,DEC);
  ansi.xy(20,4);
  Serial.print(" ");
  Serial.print(timing);
  Serial.print(" ms for each line"); 
  ansi.boldOff();
}

boolean getNumbersFromSerial() {
 while(Serial.available() <  TIME_MSG_LEN ){ ;} // time message consists of a header and ten ascii digits
    if( Serial.read() == TIME_HEADER ) { 
      Serial.println("good");      
      time_t pctime = 0;
      for(int i=0; i < TIME_MSG_LEN -1; i++){   
        char c= Serial.read();
Serial.print(c);        
        if( c >= '0' && c <= '9'){   
          pctime = (10 * pctime) + (c - '0') ; // convert digits to a number    
        }
      }
      pctime += 10;   
      DateTime.sync(pctime);   // Sync Arduino clock to the time received on the serial port
      Serial.println("syncd");
      return true;   // return true if time message received on the serial port
    }  
    return false;  //if no message return false
  }
  
  
  void printDigits(byte digits){
  // utility function for digital clock display: prints preceding colon and leading 0
  Serial.print(":");
  if(digits < 10)  Serial.print('0');
  Serial.print(digits,DEC);
  }
