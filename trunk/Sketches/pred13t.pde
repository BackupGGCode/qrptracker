//#include <TleEEPROM.h>
#include <DateTimeStrings.h>
#include <Plan13.h>
#include <DateTime.h>
//#include <avr/power.h>
//#include <avr/sleep.h>


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
#define RANGE_POS 50
#define RX_POS 60
#define TX_POS 70
#define DEBUG false
#define NUMBER_OF_TLES 6
boolean dateTimeStart = false;
Ansiterm ansi;
Plan13 p13;
long timing;
//TleEEPROM te = TleEEPROM();
//These were updated on 2010-05-26
 char * elements[NUMBER_OF_TLES][3]={
             {"CO-57",
             "1 27848U 03031J   10144.03510745  .00000045  00000-0  41505-4 0  8022",
             "2 27848  98.7132 152.4464 0008728 245.7141 114.3119 14.20500354357612"},
             {"AO-51",
              "1 28375U 04025K   10143.91004629  .00000034  00000-0  22686-4 0  6842",
              "2 28375  98.0620 138.7913 0083381 170.3282 189.9535 14.40685263310014"}
           ,
          {"AO-07",
           "1 07530U 74089B   10145.05884410 -.00000027  00000-0  10000-3 0  7840",
           "2 07530 101.4008 161.8228 0011893 321.4672  38.5544 12.53578423625558"},
          {"VO-52",
            "1 28650U 05017B   10144.09300472 -.00000043  00000-0  11413-5 0  5099",
            "2 28650  97.6949 198.4649 0027007 358.3773   1.7355 14.81746848273127"},
          {"HO-68",
            "1 36122U 09072B   10145.14169569 -.00000045  00000-0  00000+0 0  3346",
            "2 36122 100.4697 205.8025 0007853  30.6463 329.5107 13.16280683 21187"}        
            ,
           {"AO-27",
             "1 22825U 93061C   10144.98167226  .00000014  00000-0  22412-4 0  5377",
             "2 22825  98.4855  93.5340 0008021 344.4174  15.6760 14.29297866868733"}
        
         };
 void rest(int forHowLong) {
  long limit = millis() + forHowLong; 
   while (millis() < limit) {
    // set_sleep_mode(SLEEP_MODE_IDLE);
    // sleep_enable();
     /*

    */
  //   sleep_mode();
   }
 }

void setup() {
//   power_adc_disable(); //7.28 - 7.33 mA
 // power_spi_disable();
//  power_twi_disable();// with all of these, around 6.3 mA
  //  power_timer2_disable();// seems to make things worse!
  Serial.begin(57600);
   p13.setFrequency(435300000, 1459200000);//AO-51  frequency
   p13.setLocation(-64.375, 45.8958, 60); // Sackville, NB
  //readElements();
  //p13.setElements(1997.0, 126.71404377, 98.5440, 201.9624, 0.0009615, 356.5498,
  //3.5611, 14.27977735, 2.500E-07, 18818, 180.0); //fairly recent keps for AO-51
}

void loop() {
  if (DateTime.available()) {
    if (dateTimeStart) {
      layout();
      dateTimeStart = false;
    }
    for (int x = 0; x < NUMBER_OF_TLES; x++) {
      timing = millis();
    readElements(x);
    p13.setTime(DateTime.Year+1900, DateTime.Month+1, DateTime.Day, DateTime.Hour, DateTime.Minute, DateTime.Second); 
    
    p13.calculate(); 
    timing = millis() - timing;
    displayTime();
    displaySatInfo(SAT_INFO_START_ROW + x, elements[x][0]);//on row 3
    rest(100);
  }
  }
  else {
    getTime();
    dateTimeStart = true;
  }
  rest(2000);
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
  ansi.xy(AZ_POS,title_row);
  Serial.print("AZ");
  ansi.xy(EL_POS,title_row);
  Serial.print("El");
  ansi.xy(LAT_POS,title_row);
  Serial.print("Lat");
  ansi.xy(LON_POS,title_row);
  Serial.print("Lon");
  ansi.xy(RANGE_POS,title_row);
  Serial.print("Range");
  ansi.xy(RX_POS,title_row);
  Serial.print("RX");
  ansi.xy(TX_POS,title_row);
  Serial.print("TX");

}
  
void displaySatInfo(int row, char * name) {
 // float rx = p13.rxFrequency * (1.0 - p13.RR / 299792.0);
 // float tx = p13.txFrequency  * (1.0 + p13.RR / 299792.0);
  ansi.boldOn();
    ansi.setForegroundColor(WHITE);
  ansi.setBackgroundColor(BLUE);
  ansi.xy(NAME_POS,row);
  Serial.print(name);
  ansi.xy(AZ_POS,row);
  if (p13.AZ < 100.0) {
    Serial.print(" ");
  }
  Serial.print(p13.AZ);
  ansi.xy(EL_POS,row);
  Serial.print(p13.EL);
  ansi.xy(LAT_POS,row);
  Serial.print(p13.SLAT);
  ansi.xy(LON_POS,row);
  Serial.print(p13.SLON);
  ansi.xy(RX_POS,row);
  Serial.print(p13.rxOut);
  ansi.xy(TX_POS,row);
  Serial.print(p13.txOut);
}

/*
void displaySatInfo(int row) {
  ansi.setForegroundColor(WHITE);
  ansi.setBackgroundColor(BLUE);
  ansi.xy(NAME_POS,row);
  Serial.print("AO-51");
  ansi.xy(AZ_POS,row);
  Serial.print("123.45");
  ansi.xy(EL_POS,row);
  Serial.print("43.25");
  ansi.xy(RX_POS,row);
  Serial.print("435329010");
  ansi.xy(TX_POS,row);
  Serial.print("145911023");
}
*/
void getTime() {
  ansi.eraseScreen();
  ansi.boldOn();
  ansi.xy(0,0);
  Serial.print("Enter @Seconds since Jan 1, 1970: (unix command 'date +%s'):");
  if (getNumbersFromSerial() == false) {
    ansi.eraseLine();
    ansi.xy(0,0);
    Serial.println("error");
    //delay(500);
    //getTime();
    DateTime.sync(1254163584);
  }

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

   void readElements(int x)//order in the array above
{
 // for example ...
 // char line1[] = "1 28375U 04025K   09232.55636497 -.00000001  00000-0 12469-4 0   4653";
 // char line2[] = "2 28375 098.0531 238.4104 0083652 290.6047 068.6188 14.40649734270229";

        p13.setElements(getElement(elements[x][1],19,20) + 2000, getElement(elements[x][1],21,32), getElement(elements[x][2],9,16), 
         getElement(elements[x][2],18,25), getElement(elements[x][2],27,33) * 1.0e-7, getElement(elements[x][2],35,42), getElement(elements[x][2],44,51), getElement(elements[x][2],53,63), 
         getElement(elements[x][1],34,43), (getElement(elements[x][2],64,68) + ONEPPM), 0);
  /*
      
       p13.SATNO =  (getElement(elements[x][1], 3, 7) + ONEPPM);
       p13.RV    =  (getElement(elements[x][2],64,68) + ONEPPM);
        p13.YE    = getElement(elements[x][1],19,20) + 2000;
        p13.TE    = getElement(elements[x][1],21,32);
        p13.IN    = getElement(elements[x][2], 9,16);
        p13.RA    = getElement(elements[x][2],18,25);
        p13.EC    = getElement(elements[x][2],27,33) * 1.0e-7;
        p13.WP    = getElement(elements[x][2],35,42);
        p13.MA    = getElement(elements[x][2],44,51);
        p13.MM    = getElement(elements[x][2],53,63);
        p13.M2    = getElement(elements[x][1],34,43);
     */   
        if (DEBUG) {
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
 
 
 
 }

/* these functions from the DateTime library example files */

void displayTime() {
  //ansi.eraseScreen();
  ansi.setBackgroundColor(RED);
  ansi.setForegroundColor(WHITE);
  ansi.boldOn();
  ansi.xy(20,3);
 // ansi.eraseLine();

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
  //Serial.print(" ");
  Serial.print(timing);
  Serial.print(" ms for each line"); 
  ansi.boldOff();
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
  
  
  void printDigits(byte digits){
  // utility function for digital clock display: prints preceding colon and leading 0
  Serial.print(":");
  if(digits < 10)  Serial.print('0');
  Serial.print(digits,DEC);
  }
