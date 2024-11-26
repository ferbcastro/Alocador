CC = as
CX = ld
LDFLAGS = -dynamic-linker /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 \
	                      /usr/lib/x86_64-linux-gnu/crt1.o \
						  /usr/lib/x86_64-linux-gnu/crti.o \
						  /usr/lib/x86_64-linux-gnu/crtn.o -lc

OBJS = exemplo.o meuAlocador.o
EXE = meuAlocador

$(EXE): $(OBJS)
	$(CX) $(OBJS) -o $(EXE) $(LDFLAGS) -g 
	@rm -f $(OBJS)

$(OBJS):
	@gcc -c exemplo.c -g
	@as meuAlocador.s -o meuAlocador.o -g
