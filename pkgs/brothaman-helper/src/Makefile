CFLAGS = -O2 -Wall -Wextra
CC = gcc
TARGET = bro-helper
SOURCE = bro-helper.c
DESTDIR = /usr/local/bin

all: $(TARGET)

$(TARGET): $(SOURCE)
	$(CC) $(CFLAGS) -static -o $(TARGET) $(SOURCE) 2>/dev/null || $(CC) $(CFLAGS) -o $(TARGET) $(SOURCE)

install: $(TARGET)
	install -D -m 755 $(TARGET) $(DESTDIR)/$(TARGET)

clean:
	rm -f $(TARGET)

.PHONY: all install clean