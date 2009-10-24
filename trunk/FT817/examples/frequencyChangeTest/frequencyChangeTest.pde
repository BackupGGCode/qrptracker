#include <NewSoftSerial.h>
#include <FT817.h>

FT817 rig;
long x;
void setup() {
  Serial.begin(38400);

//  NewSoftSerial mySerial(2,3);
//  rig.assignSerial(mySerial);
  rig.begin(9600);
}

void loop() {
  //Serial.print("Reading frequency: ");
  //Serial.println(rig.getFreqMode());
  //Serial.println(rig.getMode(),HEX);
  testFrequencyChange();
 // testModes();
  delay(500);
}

void testFrequencyChange() {
    x = 43218000;
    for (long i = 0; i < 1000000; i++) {
      rig.setFreqTest(x+i);
      //delay(100);
    }
}
void testModes() {
  char foo[8] = {0x00,0x01, 0x02, 0x03, 0x04, 0x08, 0x0A, 0x0C};
  for (int i = 0; i < 8; i++) {
  rig.setMode(foo[i]);
  delay(1000);
  }
}
