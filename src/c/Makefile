# Makefile for utf256 (UTF-256 encoder/decoder)

CC = gcc
CFLAGS = -Wall -Wextra -O2
TARGET = utf-256
SRC = utf-256.c

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $(TARGET) $(SRC)

clean:
	rm -f $(TARGET)
