CFLAGS = -O2 -Wall -Wextra -std=c99
CC = gcc
TARGETS = bro-helper
SOURCES = bro-helper.c
DESTDIR = /usr/local/bin

all: $(TARGETS)

bro-helper: bro-helper.c
	$(CC) $(CFLAGS) -static -o $@ $< 2>/dev/null || $(CC) $(CFLAGS) -o $@ $<

install: $(TARGETS)
	install -D -m 755 bro-helper $(DESTDIR)/bro-helper

clean:
	rm -f $(TARGETS)

.PHONY: all install clean