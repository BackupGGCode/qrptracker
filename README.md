# qrptracker
This project provides [Arduino](http://www.arduino.cc) C++ libraries for tracking satellites. It includes:
  1. an implementation of the [Plan-13](http://www.amsat.org/amsat/articles/g3ruh/111.html) algorithm of James Miller
  1. a means of storing and accessing keplerian elements in EEPROM
  1. a flexible morse signaling library
  1. a library to control the Yaesu FT-817 amateur radio through its CAT interface
  1. a library to simplify the use of Ansi terminal signals.
The examples provided generate real-time satellite location and azimuth / elevation data for up to fifteen satellites using a single $4 chip, the ATMega328. With a small additional EEPROM, dozens of satellites can be tracked in real time. qrpTracker is meant for amateur satellite enthusiasts and computing hobbyists.

(This project is not a complete trackbox. If you need a complete and functional tracking solution, consider the [LVB Tracker](http://www.amsat-na.com/store/item.php?id=100151), designed and programmed by G6LVB.)
