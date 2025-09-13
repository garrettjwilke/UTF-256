DMD = ldc2
SRC = utf256.d
OUT = utf256
FINAL = utf-256

.PHONY: all clean

all: $(FINAL)

$(FINAL): $(OUT)
	mv $(OUT) $(FINAL)

$(OUT): $(SRC)
	$(DMD) $(SRC) -of=$(OUT)

clean:
	rm -f $(OUT) $(FINAL) *.o *.obj
