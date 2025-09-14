# Makefile for utf-256 (haskell version)

APP_NAME = utf-256
SRC_FILE = ${APP_NAME}.hs

.PHONY: all clean build

all: build

build:
	ghc ${SRC_FILE} -o ${APP_NAME}

clean:
	rm -f ${APP_NAME} ${APP_NAME}.o ${APP_NAME}.hi
