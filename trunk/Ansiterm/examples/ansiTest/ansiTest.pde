#include <Ansiterm.h>

char * messages[][3] = {{"Name", "Age", "Favorite Sport"}, {"Bruce", "42", "Arduino"}, {"John", "23", "Baseball"}, {"Joel", "9", "Swimming"}, {"Phoebe", "14", "Highland Dancing"}};

Ansiterm ansi;
void setup() {
  Serial.begin(38400);
}

void loop() {
  splash("Testing 'forward', 'backward', 'up', 'down', and overwriting ...");
  ansi.home();//works
  ansi.eraseScreen();
  ansi.setBackgroundColor(BLUE);//works
  ansi.setForegroundColor(GREEN);//realterm doesn't do this, macos does
  ansi.forward(10);//works
  Serial.write("10");
  ansi.forward(10);
  Serial.write("20");
  ansi.forward(10);
  Serial.write("30");
 ansi.down(1);

  ansi.setBackgroundColor(RED);
  ansi.setForegroundColor(WHITE);
  Serial.print("White on red, to be erased");
  delay(1000);
  ansi.eraseLine();//works
  ansi.up(1);//works
  ansi.backward(50);
  Serial.print("One line above, this to be written over");
  ansi.backward(20);
  ansi.setForegroundColor(BLACK);
  delay(2000);
  Serial.print("this appears over the last line");
  delay(2000);
  splash("Testing tabs (doesn't seem to work)");
  ansi.setTabAtColumn(33);//doesn't seem to work
  ansi.setTabAtColumn(66);
  Serial.write(9);
  Serial.write("33");
  Serial.write(9);
  Serial.write("66");
  
  splash("Testing xy function ...");
  ansi.setBackgroundColor(YELLOW);
  ansi.setForegroundColor(BLACK);
  ansi.eraseScreen();
  
  for (int x = 1; x < 60; x+=10) {
    delay(200);
    for (int y = 1; y < 14;  y +=2) {
      ansi.xy(x,y);
      Serial.print(x,DEC);
      Serial.print(",");
      Serial.print(y,DEC);
      delay(200);
    }
  }
  
  ansi.eraseScreen();
  delay(1000);
  splash("Making a table ...");
  //ansi.setBackgroundColor(MAGENTA);
  //ansi.setForegroundColor(YELLOW);
  for (int x = 0; x < 3; x++) {
    for (int y = 0; y < 4; y++) {
      ansi.xy(x*20,y+1);    
    if (y == 0) {
      ansi.setForegroundColor(GREEN);
    }
    else {ansi.setForegroundColor(WHITE);
    }
    Serial.print(messages[y][x]);
    }
  }
  delay(4000);
  ansi.eraseScreen();
}

void splash(char * message) {
    ansi.setBackgroundColor(BLACK);
   ansi.eraseScreen();//works
  ansi.home();
  ansi.setBackgroundColor(GREEN);
  Serial.print(message);
  delay(1000);
      ansi.setBackgroundColor(BLACK);
   ansi.eraseScreen();
}
