CC=clang
CFLAGS=-g `llvm-config --cflags`
LD=clang++
LDFLAGS=-shared `llvm-config --ldflags --libs core executionengine mcjit interpreter analysis native bitwriter --system-libs`

all: libllvmRacket.dylib

%.o: %.c
	$(CC) $(CFLAGS) -c $<

libllvmRacket.dylib: test.o
	$(LD) $< $(LDFLAGS) -o $@

clean:
	rm test.o libtest.dylib
