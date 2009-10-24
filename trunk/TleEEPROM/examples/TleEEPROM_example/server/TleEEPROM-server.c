#include "./TleEEPROM-server.h"
#include <string.h>
#include <termios.h>
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/signal.h>
#include <sys/types.h>
#include <stdlib.h>
#include <stdint.h>
#define BAUDRATE B38400
#define MODEMDEVICE "/dev/ttyS1"
#define _POSIX_SOURCE 1          //POSIX compliant source
#define FALSE 0
#define TRUE 1
#define ONEPPM 1.0e-6
#define MAX_NO_OF_ELEMENTS 50

/* keplerians */


struct modelineStruct modelines[25];
struct tleStruct satellites[MAX_NO_OF_ELEMENTS];

//char * satNames[81][NO_OF_ELEMENTS];
char tlefile[] = "nasa.tle";
char modelinesFileName[] = "Doppler.SQF";
int numberOfSats = 0;

volatile int STOP=FALSE;

int wait_flag=TRUE;              //TRUE while no signal received
char devicename[80];
long Baud_Rate = 38400;          // default Baud Rate (110 through 38400)
long BAUD;                       // derived baud rate from command line
long DATABITS;
long STOPBITS;
long PARITYON;
long PARITY;
int Data_Bits = 8;               // Number of data bits
int Stop_Bits = 1;               // Number of stop bits
int Parity = 0;                  // Parity as follows:
// 00 = NONE, 01 = Odd, 02 = Even, 03 = Mark, 04 = Space
int Format = 4;
FILE *input;
FILE *output;
int status;
int bytesOutCount = 0;           //a global
int modelineCounter = 0; // a global
int satCount = 0; // a global
int maxBytes = 0;
struct termios options;

short calculateTleAddress(int order) {
	return 4 + 46 * order;
}

void dump(void *obj, int size )
{
  int i;
  unsigned char *p = (unsigned char *)obj;
  for (i  = 0 ; i < size ; i++ )
  {
    putchar(*p++);
  }
}


int serialport_read_char(int fd, char * buf)
{
    char b[1];
	int n;
   do {
         n = read(fd, b, 1);  // read a char at a time
        if( n==-1) return -1;    // couldn't read
        if( n==0 ) {
            usleep( 10 * 1000 ); // wait 10 msec try again
			continue;
        }
        if (n > 0) { 
        buf[0] = b[0];
        buf[1] = 0; 
		return 0;
	}
	} while(n < 1);
 
  //  buf[i] = 0;  // null terminate the string
    return 0;
}

int serialport_read_until(int fd, char * buf, char until)
{
    char b[1];
    int i=0;
    do {
        int n = read(fd, b, 1);  // read a char at a time
        if( n==-1) return -1;    // couldn't read
        if( n==0 ) {
            usleep( 10 * 1000 ); // wait 10 msec try again
            continue;
        }
        buf[i] = b[0]; i++;
    } while( b[0] != until );

    buf[i] = 0;  // null terminate the string
    return 0;
}

void dumpSerial(int fd, void *obj, int size )
{
  int i;
  unsigned char *p = (unsigned char *)obj;
  for (i  = 0 ; i < size ; i++ )
  {
    write(fd,p++,1);
    bytesOutCount++;
  }
}

int dumpSerialAk(int fd, void *obj, int size )

{
		printf("*");
  int i;
int response;
  unsigned char *p = (unsigned char *)obj;
  for (i  = 0 ; i < size ; i++ )
  {
	response = 	writeAk(fd,p++,1);
if (response == -1) 
{
	return -1;
}
    bytesOutCount++;
  }
return 0;
}

int writeAk(int fd, char * p, int count) {
//	printf("writeAk:");
	write(fd,p,count);
	char buf[20];
 int i = 	serialport_read_char(fd, buf);
uint8_t ingoing = (uint8_t) *p;
uint8_t outcoming = (uint8_t) buf[0];

//	printf("wrote: %i; got: %i\n",ingoing,outcoming);
 if (ingoing != outcoming) {
	puts("HELP: I didn't get the right response!");
	exit(1);
	return -1;
}	
else {
	return 0;
}
}

void dumpDataSerial(int fd)
{

	puts("dumpDataSerial");
                             //want this to be 2-byte sized because that is the same as the
 //AVR
  unsigned short foo = (short) satCount;
 
                                 // the first 2 characters is the number of birds in the EEPROM
  dumpSerialAk(fd,&foo,sizeof(foo));
  unsigned short bar = modelineCounter;
                                 // bytes 3&4  is the number of modelines
  dumpSerialAk(fd,&bar,sizeof(bar));
  int x =0;


  for (x = 0; x < satCount; x++)

  {

    dumpSerialAk(fd,satellites[x].name,sizeof(satellites[x].name));
    dumpSerialAk(fd,&satellites[x].YE,sizeof(satellites[x].YE));
    dumpSerialAk(fd,&satellites[x].TE,sizeof(satellites[x].TE));
    dumpSerialAk(fd,&satellites[x].M2,sizeof(satellites[x].M2));
    dumpSerialAk(fd,&satellites[x].IN,sizeof(satellites[x].IN));
    dumpSerialAk(fd,&satellites[x].RA,sizeof(satellites[x].RA));
    dumpSerialAk(fd,&satellites[x].EC,sizeof(satellites[x].EC));
    dumpSerialAk(fd,&satellites[x].WP,sizeof(satellites[x].WP));
    dumpSerialAk(fd,&satellites[x].MA,sizeof(satellites[x].MA));
    dumpSerialAk(fd,&satellites[x].MM,sizeof(satellites[x].MM));
    dumpSerialAk(fd,&satellites[x].RV,sizeof(satellites[x].RV));

//	dumpSerialAk(fd,&satellites[x],sizeof(satellites[x]));
//printf("Size of object satellite: %i",sizeof(satellites[x]));
  }


for (x  = 0; x < modelineCounter; x++) {
//	dumpSerialAk(fd,&modelines[x],sizeof(modelines[x]));
//	printf("Size of object modeline: %i",sizeof(modelines[x]));
//whyohwhy don't structs get properly reconstructed on the arduino?
	dumpSerialAk(fd,&modelines[x].satAddress,sizeof(modelines[x].satAddress)); //2bytes
	dumpSerialAk(fd,&modelines[x].modeName,sizeof(modelines[x].modeName)); //5 bytes
	dumpSerialAk(fd,&modelines[x].dlLong, sizeof(modelines[x].dlLong)); //4 bytes
	dumpSerialAk(fd,&modelines[x].ulLong, sizeof(modelines[x].ulLong)); // 4 bytes
	dumpSerialAk(fd,&modelines[x].dlMode, sizeof(modelines[x].dlMode)); // 1 byte
	dumpSerialAk(fd,&modelines[x].ulMode, sizeof(modelines[x].ulMode)); // 1 byte
	dumpSerialAk(fd,&modelines[x].polarity, sizeof(modelines[x].polarity)); // 1 byte
	dumpSerialAk(fd,&modelines[x].dlShift, sizeof(modelines[x].dlShift));  // 4 bytes
	dumpSerialAk(fd,&modelines[x].ulShift, sizeof(modelines[x].ulShift));  //4 bytes
	//26 bytes total.
	
	}


}



void dumpData()
{
                                 //want this to be 2-byte sized because that is the same as the
  unsigned short foo = satCount;
  //AVR
  dump(&foo,sizeof(foo));        // the first character is the number of birds in the EEPROM
  unsigned short bar = 0;
  dump(&bar,sizeof(bar));        // second byte is the number of modelines
  int x =0;
  //fputs(sizeof(satellites[0]),output);
  for (x = 0; x < satCount; x++)
  {
    dump(satellites[x].name,sizeof(satellites[x].name));
    dump(&satellites[x].YE,sizeof(satellites[x].YE));
    dump(&satellites[x].TE,sizeof(satellites[x].TE));
    dump(&satellites[x].M2,sizeof(satellites[x].M2));
    dump(&satellites[x].IN,sizeof(satellites[x].IN));
    dump(&satellites[x].RA,sizeof(satellites[x].RA));
    dump(&satellites[x].EC,sizeof(satellites[x].EC));
    dump(&satellites[x].WP,sizeof(satellites[x].WP));
    dump(&satellites[x].MA,sizeof(satellites[x].MA));
    dump(&satellites[x].MM,sizeof(satellites[x].MM));
    dump(&satellites[x].RV,sizeof(satellites[x].RV));
  }
}


float getElement(char *gstr, int gstart, int gstop)
{
  float retval;
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


handshake(int fd) {
	char buf[10];
	serialport_read_until(fd, buf, '\n');
	printf("handshake, got: %s\n",buf);	
	char f = 'R';
	dumpSerial(fd,&f,sizeof(f));
	serialport_read_until(fd, buf, '\n');
	printf("handshake, got: %s\n",buf);
	
}

void writeTlesToSerial(char * devicename, int BAUD) {
      //write tle to serial
      //printf("Satellite not found...\n");
      int fd = open(devicename, O_RDWR | O_NOCTTY | O_NDELAY);
      tcgetattr(fd, &options);
      cfsetispeed(&options, BAUD);
      cfsetospeed(&options, BAUD);
      
      /*
       * Enable the receiver and set local mode...
       */

      options.c_cflag |= (CLOCAL | CREAD |  O_NDELAY);
options.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG); // raw input
options.c_iflag &= ~(IXON | IXOFF | IXANY); // no flow control

options.c_cflag &= ~CRTSCTS; //disable hardware flow control

options.c_cflag &= ~PARENB;
options.c_cflag &= ~CSTOPB;
 options.c_cflag &= ~CSIZE; /* Mask the character size bits */
    options.c_cflag |= CS8;    /* Select 8 data bits */
    options.c_cc[VMIN]  = 0;
    options.c_cc[VTIME] = 20;
//	options.c_oflag &= ~ONLCR;// really try to not do cr = ln&cr
options.c_oflag &= ~OPOST; //raw output
      /*
       * Set the new options for the port...
       */

      tcsetattr(fd, TCSANOW, &options);

      if (fd < 0)
      {
        perror(devicename);
        exit(-1);
      }
	handshake(fd);
      dumpDataSerial(fd);
      close(fd);

}

char matchModes (char * in) {
	if (!strcmp(in, "CW")) {
	return CW;
    }
	if (!strcmp(in, "USB")) {
	return USB;
    }
	if (!strcmp(in, "LSB")) {
	return LSB;
    }
	if (!strcmp(in, "FM")) {
	return FM;
    }
	if (!strcmp(in, "FMN")) {
	return FMN;
    }
    if (!strcmp(in, "PKT")) {
		return PKT;
    if (!strcmp(in, "CWN")) {
		return CWN;
	}

}
 	//now in error state
	puts("No such mode:");
		puts(in);
		exit(1);
	
}

void printModelines() {
	char satName[20];
	int x;
	printf("Modelines: %d\n",modelineCounter);
	for (x = 0; x < modelineCounter; x++) {
		printf("%s (%s):  up link:%lu, down link:%lu, ulMode: %i, dlMode: %i\n", modelines[x].modeName, modelines[x].satName,  modelines[x].ulLong,modelines[x].dlLong, modelines[x].ulMode, modelines[x].dlMode);
	}
}

void readModelines()
{
  FILE *modelinesFile;
  char buffer[81];
  char satName[20];
  char dl[20];
char ul[20];
char dlModeString[5];
char ulModeString[5];
char polarity[5];
char ulShift[20];
char dlShift[20];
char modeName[20];
modelineCounter = 0;
  if ((modelinesFile = fopen(modelinesFileName, "r")) == NULL)
  {
    perror( modelinesFileName );
    exit(0);
  }// end if modelinesFile
  for(;;)
  {
	//printf("bytes so far: %i\n", (modelineCounter + 1) * MODELINE_RECORD_SIZE + satCount * TLE_RECORD_SIZE);
	//printf("maxBytes: %i\n", maxBytes);
//	puts("in for loop");
    if (fgets(buffer, 80, modelinesFile) == NULL || (((modelineCounter + 1) * MODELINE_RECORD_SIZE) + (satCount * TLE_RECORD_SIZE)) > (maxBytes - HEADER_SIZE))
    {
	//	printModelines();
		return;
    }//end if fgets...
    // remove newline
	int len = strlen(buffer);
	if( buffer[len-1] == '\n' )
	    buffer[len-1] = 0;
    //strcat(buffer, ",F");
	//printf("current buffer line: '%s'\n", buffer);
    if (buffer[0] != ';')     {// omit commented out lines
	//	printf("at modfile line number: %d\n", modelineCounter);
	//	modeName[0] = 'x';
	//	puts(buffer);
	if (sscanf(buffer, "%[^,],%[^,],%[^,],%[^,],%[^,],%[^,],%[^,],%[^,],%[^,]", satName, dl, ul, dlModeString, ulModeString,polarity,ulShift,dlShift,modeName) == 8) {
		strcat(buffer, ",noname");
	}
    sscanf(buffer, "%[^,],%[^,],%[^,],%[^,],%[^,],%[^,],%[^,],%[^,],%[^,]", satName, dl, ul, dlModeString, ulModeString,polarity,ulShift,dlShift,modeName);
	int x;
//	printf("modeline satname: %s\n", satName);
		double dlDouble, ulDouble;
	for (x = 0; x < satCount; x++)
  {
	//printf("at satellite[x]: %s\n", satellites[x].name);

	if (!strcmp(satellites[x].name, satName)) 
	{
	//	puts("MATCH!");
		modelines[modelineCounter].satAddress = calculateTleAddress(x);
	    strncpy(modelines[modelineCounter].satName, satName,5);
		dlDouble = atof(dl);
		ulDouble = atof(ul);
		modelines[modelineCounter].dlLong = (long) ((10.0 * dlDouble) + 0.5);
		modelines[modelineCounter].ulLong = (long) ((10.0 * ulDouble) + 0.5);
		modelines[modelineCounter].dlMode = matchModes(dlModeString);
		modelines[modelineCounter].ulMode = matchModes(ulModeString);
		if (!strcmp(polarity, "REV")) {
			modelines[modelineCounter].polarity = REV;
		}
		else {
			modelines[modelineCounter].polarity = NOR;
		}// end if !strcmp
        modelines[modelineCounter].ulShift = atof(ulShift);
        modelines[modelineCounter].dlShift = atof(dlShift);
		strncpy(modelines[modelineCounter].modeName,modeName,5);
		modelineCounter++;
		break;//Kill for loop. no need to keep scanning for this satellite name.
	}//end if satellites[x]

}//end for x = 0
}//end if buffer[0]
else {
//	printf("comment line: %s",buffer);
}
}// end for (;;)
}//end function



void readElements()
{
  FILE *tle;
  char buffer[81];
  char line1[81];
  char line2[81];

  if ((tle = fopen(tlefile, "r")) == NULL)
  {
    perror( tlefile );
    exit(0);
  }
  satCount = 0;
  for(;;)
  {
    if (fgets(buffer, 80, tle) == NULL)
    {
		return;
    }
//	printf("elements bytes: %i\n", satCount * TLE_RECORD_SIZE);
//	printf("maxBytes: %i\n", maxBytes);
    if (buffer[0] != '1' && buffer[0] != '2' && ((satCount + 1) * TLE_RECORD_SIZE) <= (maxBytes - HEADER_SIZE))
    {
                                 //dies if I make it six
      	int len = strlen(buffer);
		if( buffer[len-1] == '\n' )
		    buffer[len-1] = 0;
      strncpy(satellites[satCount].name,buffer,5);
      printf("%s\n", buffer);
      fgets(line1, 80, tle);
      fgets(line2, 80, tle);
      printf("%s%s\n", line1, line2);


      satellites[satCount].YE    = getElement(line1,19,20) + 2000;

      satellites[satCount].TE    = getElement(line1,21,32);
      satellites[satCount].M2    = getElement(line1,34,43);
      satellites[satCount].IN    = getElement(line2, 9,16);
      satellites[satCount].RA    = getElement(line2,18,25);
      satellites[satCount].EC    = getElement(line2,27,33) * 1.0e-7;
      satellites[satCount].WP    = getElement(line2,35,42);
      satellites[satCount].MA    = getElement(line2,44,51);
      satellites[satCount].MM    = getElement(line2,53,63);
      satellites[satCount].RV    =  (getElement(line2,64,68) + ONEPPM);
      
      /*
      printf("RV %ld\n", satellites[satCount].RV);
      printf("YE %d\n", satellites[satCount].YE);
      printf("TE %f\n", satellites[satCount].TE);
      printf("IN %f\n", satellites[satCount].IN);
      printf("RA %f\n", satellites[satCount].RA);
      printf("EC %f\n", satellites[satCount].EC);
      printf("WP %f\n", satellites[satCount].WP);
      printf("MA %f\n", satellites[satCount].MA);
      printf("MM %f\n", satellites[satCount].MM);
      printf("M2 %f\n\n", satellites[satCount].M2);
      */
      // break;
      satCount++;
    }
  }
}


int main(int Parm_Count, char *Parms[])
{
  char Param_strings[2][80];
  if (Parm_Count==4)             //if there are the right number of parameters on the command line
  {
    int i;
    int error = 0;
                                 // for all wild search parameters
    for (i=1; i < Parm_Count; i++)
    {
      strcpy(Param_strings[i-1],Parms[i]);
    }
    i=sscanf(Param_strings[0],"%s",devicename);
    if (i != 1) error=1;

   i=sscanf(Param_strings[1],"%li",&Baud_Rate);
    if (i != 1) error=1;
    switch (Baud_Rate)
    {
      case 38400:
      default:
        BAUD = B38400;
        break;
      case 19200:
        BAUD  = B19200;
        break;
      case 9600:
        BAUD  = B9600;
        break;
      case 4800:
        BAUD  = B4800;
        break;
      case 2400:
        BAUD  = B2400;
        break;
      case 1800:
        BAUD  = B1800;
        break;
      case 1200:
        BAUD  = B1200;
        break;
      case 600:
        BAUD  = B600;
        break;
      case 300:
        BAUD  = B300;
        break;
      case 200:
        BAUD  = B200;
        break;
      case 150:
        BAUD  = B150;
        break;
      case 134:
        BAUD  = B134;
      case 110:
        BAUD  = B110;
        break;
      case 75:
        BAUD  = B75;
        break;
      case 50:
        BAUD  = B50;
        break;
    

}                         //end of switch baud_rate

i  = sscanf(Param_strings[2],"%i",&maxBytes);
if (i != 1) error = 1;
   if (error == 1) {
	puts("Incorrect usage: qrpWriteEEPROM SERIAL_DEVICE SPEED BYTES");
	exit(1);
}
    readElements();

//	dumpData();
	readModelines();
	if (satCount > 0) {
    writeTlesToSerial(devicename, BAUD);
	printModelines();
	printf("Tles: %i\n", satCount);
	printf("Modelines: %i\n", modelineCounter);
	printf("Bytes out: %i\n", bytesOutCount);
 exit(0);
  }
else {puts("Space too small to fit a single TLE");}
  }
  else {
	puts("Usage: qrpWriteEEPROM SERIAL_DEVICE SPEED BYTES");
	}
	return 1;
}
