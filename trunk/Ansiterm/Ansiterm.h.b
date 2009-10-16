
#ifndef Ansiterm_h
#define Ansiterm_h
#include "WProgram.h"
#define ESCAPE 0x1B
#define BRACE '['
#define BLACK 0
#define RED 1
#define GREEN 2
#define YELLOW 3
#define BLUE 4
#define MAGENTA 5
#define CYAN 6
#define WHITE 7
#define BOLD_ON 1
#define BOLD_OFF 22
#define UNDERLINE_ON 4
#define UNDERLINE_OFF 24
#define ITALICS_ON 3
#define ITALICS_OFF 23
#define STRIKETHROUGH_ON 9
#define STRIKETHROUGH_OFF 29
#define INVERSE_ON 7
#define INVERSE_OFF 27
#define RESET 1
#define DEFAULT_FOREGROUND 39
#define DEFAULT_BACKGROUND 49

class Ansiterm
{

  public:
    Ansiterm();
    void home();
    void xy(int x, int y);
    void up(int x);
    void down(int x);
    void forward(int x);
    void backward(int x);
    void eraseLine();
    void eraseScreen();
    void setBackgroundColor(int color);
    void setForegroundColor(int color);
    void boldOn();
    void boldOff();
    void underlineOn();
    void underlineOff();
    void italicsOn();
    void italicsOff();
    void strikethroughOn();
    void strikethroughOff();
    void inverseOn();
    void inverseOff();
    void reset();
    void defaultBackground();
    void defaultForeground();
    void fill(int x1, int y1, int x2, int y2);
  private:
    void preamble();
    void preambleAndNumberAndValue(int x, char v);
    void setAttribute(int a);

};
#endif
