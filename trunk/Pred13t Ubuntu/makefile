CC=g++
CFLAGS=-c -Wall -Wno-write-strings
LDFLAGS=
SOURCES=Pred13t.cpp
OBJECTS=$(SOURCES:.cpp=.o)
EXECUTABLE=thirteen

all: $(SOURCES) $(EXECUTABLE)
	
$(EXECUTABLE): $(OBJECTS) 
	$(CC) $(LDFLAGS) $(OBJECTS) -o $@

.cpp.o:
	$(CC) $(CFLAGS) $< -o $@

clean:
	rm -f *.o core

rebuild: clean all
