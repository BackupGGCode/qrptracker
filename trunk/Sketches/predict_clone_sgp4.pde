#include <DateTimeStrings.h>
#include <Pred13t.h>
#include <DateTime.h>
#include <Math.h>
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
long timing;
Pred13t predict;
char * elements[NUMBER_OF_TLES][3]={
             {"CO-57",
             "1 27848U 03031J   10144.03510745  .00000045  00000-0  41505-4 0  80220",
             "2 27848  98.7132 152.4464 0008728 245.7141 114.3119 14.20500354357612"},
             {"AO-51",
              "1 28375U 04025K  10143.91004629  .00000034  00000-0  22686-4 0  68420",
              "2 28375  98.0620 138.7913 0083381 170.3282 189.9535 14.40685263310014"},
              {"AO-07",
              "1 07530U 74089B  10145.05884410 -.00000027  00000-0  10000-3 0  78400",
              "2 07530 101.4008 161.8228 0011893 321.4672  38.5544 12.53578423625558"},
              {"VO-52",
              "1 28650U 05017B  10144.09300472 -.00000043  00000-0  11413-5 0  50990",
              "2 28650  97.6949 198.4649 0027007 358.3773   1.7355 14.81746848273127"},
              {"HO-68",
              "1 36122U 09072B  10145.14169569 -.00000045  00000-0  00000+0 0  33460",
              "2 36122 100.4697 205.8025 0007853  30.6463 329.5107 13.16280683 21187"},
              {"AO-27",
              "1 22825U 93061C  10144.98167226  .00000014  00000-0  22412-4 0  53770",
              "2 22825  98.4855  93.5340 0008021 344.4174  15.6760 14.29297866868733"}
         };



void setup() {
  Serial.begin(57600);
  Serial.println("Ok");
 // predict.setTime(0);
 // predict.calc(predict.co57);
}

void loop() {
 if (DateTime.available()) {
  if (dateTimeStart){
    layout();
    Serial.println("true");
    dateTimeStart = false;
  }
  else{
    getTime();
    Serial.println("false");
    dateTimeStart = true;
  }
 predict.setTime(0);
 predict.calc(predict.co57);
 }
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
