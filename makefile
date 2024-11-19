CC = as
CX = ld
LDFLAGS = -dynamic-linker /lib/ld-linux-x86-64.so.2 /usr/lib/crt1.o /usr/lib/crti.o /usr/lib/crtn.o -lc

OBJS = exemplo.o meuAlocador.o
EXE = meuAlocador

$(EXE): $(OBJS)
	$(CX) $(OBJS) -o $(EXE) $(LDFLAGS) -g 
	@rm -f $(OBJS)

$(OBJS):
	@gcc -c exemplo.c -g
	@as meuAlocador.s -o meuAlocador.o -g
