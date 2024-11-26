#include <stdio.h>
#include "meuAlocador.h"

int main (long int argc, char** argv) {
  void *a, *b;

  iniciaAlocador();               // Impressão esperada
  imprimeMapa();                  // <vazio>

  a = (void *) alocaMem(4063);
  imprimeMapa();                  // ################**********
  // b = (void *) alocaMem(4);
  // imprimeMapa();                  // ################**********##############****
  // liberaMem(a);
  // imprimeMapa();                  // ################----------##############****
  // liberaMem(b);                   // ################----------------------------
  //                                 // ou
  //                                 // <vazio>
  // imprimeMapa();

  a = (void *) alocaMem(6);
  imprimeMapa();
  liberaMem(a);
  imprimeMapa();
  finalizaAlocador();
}
