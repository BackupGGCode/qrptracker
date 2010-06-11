#include <DateTimeStrings.h>
#include <SGP4ATmega.h>
#include <DateTime.h>
//#include <Math.h>
#include <Ansiterm.h>
#include <stdlib.h>
#define DEBUG

#ifdef DEBUG
  #define DEBUG_PRINT(x)   Serial.print (x)
  #define DEBUG_PRINTLN(x) Serial.println (x)
#else
  #define DEBUG_PRINT(x)
  #define DEBUG_PRINTLN(x)
#endif

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

#define NUMBER_OF_TLES 6
boolean dateTimeStart = false;
Ansiterm ansi;
long timing;
            SGP4ATmega predict;
SGP4ATmega::geodetic_t *latlon, zero= {0,0,0,0};
char * elements[NUMBER_OF_TLES][3]={
    {"CO-57",
        "1 27848U 03031J  10144.03510745  .00000045  00000-0  41505-4 0  80220",
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

/*SGP4ATmega::tle_t co57 = {10,
  144.03510745,//ye, then time
  .00000045,//ndot/2 drag parameter
  00000.0,//n float dot/6 Drag Parameter
  0.000042, //bstar drag parameter
  98.7132,//inclination IN
  152.4464, //RA
  .000873,//eccentricity EC
  245.714100, //WP
  114.3119,//mean anomaly MA
  14.20500354,//mean motion MM
  3031, //Sat cat number
  8022, // element set number
  35761,//reveloution Numf                                                                                                        ber at Epoch
  "CO-57", "03031J"};//international Designation*/
  
  
  
//void * operator new(size_t size);
//void operator delete(void * ptr);
//
//void * operator new(size_t size)
//{
//  DEBUG_PRINTLN("IM NEW!!!!");
//  return malloc(size);
//}
//
//void operator delete(void * ptr)
//{
//  DEBUG_PRINTLN("IM FREEEEEEE!!");
//  free(ptr);
//}

void rest(int forHowLong) {
    long limit = millis() + forHowLong; 
    while (millis() < limit) {
    }
}

void setup() {
    Serial.begin(57600);
    #ifdef DEBUG
        ansi.eraseScreen();
    #endif
    //Serial.println("Main Screen turn on.");
}

void loop() {
    if (DateTime.available()) {
        if(dateTimeStart){
            DEBUG_PRINT("dateStart = true;");                
            #ifndef DEBUG
                layout();
            #endif
            dateTimeStart = false;
        }
        for (int x=0; x < NUMBER_OF_TLES;x++){

            timing = millis();
            DEBUG_PRINTLN("Reading Elements");
            readElements(x);
            DEBUG_PRINT("Setting Time to: ");
            DEBUG_PRINTLN(DateTime.now());
            predict.setTime(DateTime.now());
            DEBUG_PRINTLN("Calculating Elements");
            latlon = &zero;
            predict.calc(predict.elements, latlon);
            timing = millis() - timing;
            #ifndef DEBUG
                displayTime();
                displaySatInfo(SAT_INFO_START_ROW + x, elements[x][0]);;
            #endif
            DEBUG_PRINT("TLENO: ");
            DEBUG_PRINTLN(x);
            DEBUG_PRINT("LAT");
            DEBUG_PRINTLN((*latlon).lat);
            #ifndef DEBUG     
                rest(100);
            #endif
        }
    }
    else{
        DEBUG_PRINTLN("Getting Time");
        DateTime.sync(1276273832);
       // getTime();
        dateTimeStart=true;
    }
    #ifdef DEBUG
        if(!dateTimeStart)
            exit(0);
    #endif
    DEBUG_PRINTLN("Resting 2000");
    #ifndef DEBUG
        rest(2000);
    #endif
}

void layout() {
    ansi.setBackgroundColor(RED);
    ansi.fill(0,0,80,4);
    ansi.setForegroundColor(WHITE);
    ansi.xy(15,2);
    ansi.boldOn();
    Serial.print("SGP4ATmega: Predict-Arduino Port Satellite Tracking Demo");
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
//    Serial.print("AZ");
//    ansi.xy(EL_POS,title_row);
//    Serial.print("El");
    ansi.xy(LAT_POS,title_row);
    Serial.print("Lat");
    ansi.xy(LON_POS,title_row);
    Serial.print("Lon");
//    ansi.xy(RANGE_POS,title_row);
//    Serial.print("Range");
//    ansi.xy(RX_POS,title_row);
//    Serial.print("RX");
//    ansi.xy(TX_POS,title_row);
//    Serial.print("TX");
}

void displaySatInfo(int row, char * name) {
 // float rx = p13.rxFrequency * (1.0 - p13.RR / 299792.0);
 // float tx = p13.txFrequency  * (1.0 + p13.RR / 299792.0);
  ansi.boldOn();
  ansi.setForegroundColor(WHITE);
  ansi.setBackgroundColor(BLUE);
  ansi.xy(NAME_POS,row);
  Serial.print(name);
//  ansi.xy(AZ_POS,row);
//  if (p13.AZ < 100.0) {
//    Serial.print(" ");
//  }
//  Serial.print(p13.AZ);
//  ansi.xy(EL_POS,row);
//  Serial.print(p13.EL);
    ansi.xy(LAT_POS,row);
    Serial.print((*latlon).lat);
    ansi.xy(LON_POS,row);
    Serial.print((*latlon).lon);
//  ansi.xy(RX_POS,row);
//  Serial.print(p13.rxOut);
//  ansi.xy(TX_POS,row);
//  Serial.print(p13.txOut);
}



void getTime() {
    #ifndef DEBUG
        ansi.eraseScreen();
        ansi.boldOn();
        ansi.xy(0,0);
    #endif
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

double getElement(char *gstr, int gstart, int gstop) {
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

void readElements(int x) {
    SGP4ATmega::tle_t sat1;
    float temp;
    sat1.catnr = getElement(elements[x][1],3,5);
    //sat1.designator = getElement(elements[x][1],9,16);
    //sat1.year = getElement(elements[x][1],19,20);
    //sat1.refepoch=getElement(elements[x][1],21,32);
    //sat.epoch=getElement(elements[x][1],19,32);
    sat1.epoch_year = getElement(elements[x][1],18,19);
    sat1.epoch_day = getElement(elements[x][1],20,31);
    //drag
    sat1.xndt2o = getElement(elements[x][1],34,43); 
    //nddot6
    temp = getElement(elements[x][1],46,50);
    if (elements[x][1][45] == '-')
        temp *= -1;
    sat1.xndd6o = temp;
    temp = pow(10,elements[x][1][52]);
    if (elements[x][1][51] == '-')
        temp *= -1;
    sat1.xndd6o *= temp;

    //bstar
    temp = getElement(elements[x][1],54,58);
    if (elements[x][1][53] == '-')
        temp *= -1;
    DEBUG_PRINT("TEMP: ");
    DEBUG_PRINTLN(temp);
    sat1.bstar = temp/100000.0;
    temp = getElement(elements[x][1],59,60);
    DEBUG_PRINT("TEMP2: ");
    DEBUG_PRINTLN(temp);
    sat1.bstar *= pow(10,temp);
    DEBUG_PRINT("BSTAR: ");
    DEBUG_PRINTLN(sat1.bstar);
    sat1.elset = getElement(elements[x][1],65,68);
    //inclination
    sat1.xincl = getElement(elements[x][2],9,16);
    sat1.xnodeo = getElement(elements[x][2],18,25);
    temp = getElement(elements[x][2],27,33);
    sat1.eo = temp / 10000000;
    sat1.omegao = getElement(elements[x][2],35,42);
    sat1.xmo = getElement(elements[x][2],44,51);
    sat1.xno = getElement(elements[x][2],53,63);
    sat1.revnum = getElement(elements[x][2],64,68);
    predict.setElements(sat1);
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
