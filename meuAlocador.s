.section .data
	str: .string "Impressao inicial\n"
	asterico: .string "#"
	mais: .string "+"
	menos: .string "-"
	quebraLinha: .string "\n"
	inicioHeap: .quad 0
	topoBrk: .quad 0
	iniUltimoBloco: .quad 0
.section .text
.global iniciaAlocador
.global finalizaAlocador
.global alocaMem
.global liberaMem
.global imprimeMapa
# =========================================================================== #
# topoInicial recebe brk e topoAtual recebe brk - 1 	   					  # 
# =========================================================================== #
iniciaAlocador: # sem parametros
	pushq %rbp
	movq %rsp, %rbp
	movq $str, %rdi
	call printf
	movq $0, %rdi
	movq $12, %rax
	syscall
	movq %rax, inicioHeap
	subq $1, %rax
	movq %rax, topoBrk
	movq $0, iniUltimoBloco
	popq %rbp
	ret
# =========================================================================== #
# Restaura o valor de brk  							    					  #
# =========================================================================== #
finalizaAlocador: # sem parametros
	pushq %rbp
	movq %rsp, %rbp
	movq inicioHeap, %rdi
	movq $12, %rax
	syscall
	popq %rbp
	ret
# =========================================================================== #
# Testa se endereco eh maior ou igual a inicioHeap                            #
# =========================================================================== #
enderecoMaiorIgualIni:
	push %rbp
	movq %rsp, %rbp
	movq inicioHeap, %r10
	cmpq %r10, %rdi
	jl else_enderecoMaiorIgualIni
	movq $1, %rax
	jmp fora_enderecoMaiorIgualIni  
else_enderecoMaiorIgualIni:
	movq $0, %rax
fora_enderecoMaiorIgualIni:
	pop %rbp
	ret
# =========================================================================== #
# Testa se endereco eh menor ou igual a topoBrk                               #
# =========================================================================== #
enderecoMenorIgualFim:
	push %rbp
	movq %rsp, %rbp
	movq topoBrk, %r10
	cmpq %r10, %rdi
	jg else_enderecoMenorIgualFim
	movq $1, %rax
	jmp fora_enderecoMenorIgualFim  
else_enderecoMenorIgualFim:
	movq $0, %rax
fora_enderecoMenorIgualFim:
	pop %rbp
	ret
# =========================================================================== #
# Recebe um ponteiro em %rdi e libera o bloco ao qual ele aponta			  #
# =========================================================================== #
liberaMem: # void*
	pushq %rbp
	movq %rsp, %rbp
	subq $48, %rsp
	movq %r12, -16(%rbp)
	movq %r13, -24(%rbp)
	movq %r14, -32(%rbp)
	movq %r15, -40(%rbp)
	movq %rdi, -8(%rbp)
	call enderecoMaiorIgualIni
	movq -8(%rbp), %rdi
	cmpq $1, %rax
	jne return_liberaMem
	call enderecoMenorIgualFim
	movq -8(%rbp), %rdi
	cmpq $1, %rax
	jne return_liberaMem
	movq $0, -16(%rdi) # libera bloco
	movq inicioHeap, %r12
	movq %r12, %r14
	movq $0, %r15 # %r15 tera tamanho do novo bloco
while_junta:
	cmpq $0, (%r12)
	jne bloco_ocupado
	addq 8(%r12), %r15
	addq $16, %r15 # adiciona bloco gerencial no espaco livre
	jmp apos_bloco_ocupado
bloco_ocupado:
	movq $0, %r15
	lea 16(%r12), %r14
	addq -8(%r14), %r14
apos_bloco_ocupado:
	addq $16, %r12
	cmpq %r12, %rdi
	je fora_while_junta
	addq -8(%r12), %r12
	jmp while_junta
fora_while_junta:
	subq $16, %r15 # remove um bloco gerencial do espaco livre
	subq $16, %r12
	cmpq iniUltimoBloco, %r12
	je bloco_eh_ultimo
	addq $16, %r12
	addq -8(%r12), %r12
	cmpq $0, (%r12)
	jne proximo_nao_esta_livre
	addq 8(%r12), %r15
	addq $16, %r15
proximo_nao_esta_livre:
bloco_eh_ultimo:
	movq $0, (%r14)
	movq %r15, 8(%r14)
return_liberaMem:
	movq -16(%rbp), %r12
	movq -24(%rbp), %r13
	movq -32(%rbp), %r14
	movq -40(%rbp), %r15
	addq $48, %rsp
	popq %rbp
	ret
# =========================================================================== #
# Aloca %rdi bytes na heap e retorna o ptr do bloco	em %rax					  #
# =========================================================================== #
alocaMem: # tamanho do bloco
	pushq %rbp
	movq %rsp, %rbp
	subq $16, %rsp
	movq $0, %rax
	cmpq $0, %rdi # verifica %rdi == 0
	je return_alocaMem
	movq inicioHeap, %rsi
	movq topoBrk, %rdx
	movq $0x7fffffffffffffff, %rcx # menor
loop_procurar_bloco:
	cmpq %rdx, %rsi
	jg fora_loop_procurar_bloco
	cmpq $0, (%rsi)
	jne bloco_nao_livre
	cmpq 8(%rsi), %rdi
	jg bloco_sem_espaco
	cmpq 8(%rsi), %rcx # compara tamanho com menor (rcx)
	jle maior_que_menor
	movq 8(%rsi), %rcx
	movq %rsi, %r8 # coloca endereco do bloco menor em r8
maior_que_menor:
bloco_sem_espaco:
bloco_nao_livre:
	addq 8(%rsi), %rsi
	addq $16, %rsi
	jmp loop_procurar_bloco
fora_loop_procurar_bloco:
	movq $0x7fffffffffffffff, %r10
	cmpq %r10, %rcx
	jne bloco_encontrado
	movq iniUltimoBloco, %r8
	cmpq $0, %r8
	je ultimo_nao_livre
	cmpq $0, (%r8)
	jne ultimo_nao_livre
	movq 8(%r8), %r9
	jmp loop_calcula_brk
ultimo_nao_livre:
	movq %rsi, %r8 # salva %rsi em %r8
	movq $-16, %r9
loop_calcula_brk:
	cmpq %r9, %rdi
	jle fora_loop_calcula_brk
	addq $4096, %rdx
	addq $4096, %r9
	jmp loop_calcula_brk
fora_loop_calcula_brk:
	movq %rdi, -8(%rbp)
	movq %rdx, %rdi
	movq $12, %rax
	syscall
	movq -8(%rbp), %rdi
	movq %rdx, topoBrk
	movq $1, %r10
	jmp novo_bloco
bloco_encontrado:
	movq 8(%r8), %r9
	cmpq iniUltimoBloco, %r8
	jne bloco_encontrado_nao_eh_ultimo
	movq $1, %r10
	jmp novo_bloco
bloco_encontrado_nao_eh_ultimo:
	movq $0, %r10
novo_bloco:
	lea 16(%r8), %rax # %r8 + 16 eh retornado
	movq $1, (%r8)
	movq %rdi, 8(%r8)
	subq %rdi, %r9
	cmpq $16, %r9
	jle bloco_nao_partido
	addq $16, %r8 # bloco livre sera partido em dois
	addq -8(%r8), %r8
	movq $0, (%r8)
	subq $16, %r9
	movq %r9, 8(%r8)
	jmp apos_bloco_nao_partido
bloco_nao_partido:
	addq %r9, 8(%r8)
apos_bloco_nao_partido:
	cmpq $1, %r10
	jne nao_atualiza_ultimo
	movq %r8, iniUltimoBloco
nao_atualiza_ultimo:
return_alocaMem:
	addq $16, %rsp
	popq %rbp
	ret
# =========================================================================== #
# Imprime um mapa da heap 													  #
# =========================================================================== #
imprimeMapa: # sem parametros
	pushq %rbp
	movq %rsp, %rbp
	subq $32, %rsp
	movq %r12, -16(%rbp)
	movq %r13, -24(%rbp)
	movq %r14, -32(%rbp)
	movq topoBrk, %r12
	movq inicioHeap, %r13
while_imprime:
	cmpq %r12, %r13
	jg fora_while_imprime
	movq $16, %r14
while_asterisco:
	movq $asterico, %rdi
	call printf
	dec %r14
	cmpq $0, %r14
	je fora_while_asterisco
	jmp while_asterisco
fora_while_asterisco:
	movq 8(%r13), %r14
	cmpq $1, (%r13)
	jne imprime_menos
	movq $mais, %rdi
	jmp while_mais_menos
imprime_menos:
	movq $menos, %rdi
while_mais_menos:
	cmpq $0, %r14
	je fora_while_mais_menos
	movq %rdi, -8(%rbp)
	call printf
	movq -8(%rbp), %rdi
	dec %r14
	jmp while_mais_menos
fora_while_mais_menos:
	addq $16, %r13
	addq -8(%r13), %r13
	jmp while_imprime
fora_while_imprime:
	movq $quebraLinha, %rdi
	call printf
	movq $quebraLinha, %rdi
	call printf
return_imprimeMapa:
	movq -16(%rbp), %r12
	movq -24(%rbp), %r13
	movq -32(%rbp), %r14
	addq $32, %rsp
	popq %rbp
	ret
	