
hasmath: hasmath.o plus.o
	ld -lcrt1.o -lSystem hasmath.o plus.o -o hasmath

%.o: %.c
	cc -c hasmath.c

# plus.o:
# 	cc -c