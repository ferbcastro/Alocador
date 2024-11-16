.section .data
	str: .string "Impressao inicial\n"
	asterico: .string "#"
	mais: .string "+"
	menos: .string "-"
	quebraLinha: .string "\n"
	topoInicialHeap: .quad 0
	topoAtualHeap: .quad 0
	topoBlocosHeap: .quad 0
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
	movq %rax, topoInicialHeap
	subq $1, %rax
	movq %rax, topoAtualHeap
	popq %rbp
	ret
# =========================================================================== #
# Restaura o valor de brk  							    					  #
# =========================================================================== #
finalizaAlocador: # sem parametros
	pushq %rbp
	movq %rsp, %rbp
	movq topoInicialHeap, %rdi
	movq $12, %rax
	syscall
	popq %rbp
	ret
# =========================================================================== #
# Testa se endereco eh maior ou igual a topoInicialHeap    					  #
# =========================================================================== #
enderecoMaiorIgualIni:
	push %rbp
	movq %rsp, %rbp
	movq topoInicialHeap, %r10
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
# Testa se endereco eh menor ou igual a topoAtualHeap   					  #
# =========================================================================== #
enderecoMenorIgualFim:
	push %rbp
	movq %rsp, %rbp
	movq topoAtualHeap, %r10
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
	subq $16, %rsp # aloca tamanho multiplo de 16 bytes
	# verifica endereco	
	pushq %rdi
	subq $16, %rdi
	call enderecoMaiorIgualIni
	pop %rdi
	cmpq $0, %rax
	je return_liberaMem
	pushq %rdi
	call enderecoMenorIgualFim
	pop %rdi
	cmpq $0, %rax
	je return_liberaMem
	# endereco valido
	movq $0, -16(%rdi)
	movq -8(%rdi), %r10
	addq %r10, %rdi
	# verifica se nao eh ultimo bloco
	pushq %r10
	pushq %rdi
	call enderecoMenorIgualFim
	pop %rdi
	pop %r10
	cmpq $0, %rax
	je return_liberaMem
	cmpq $0, (%rdi)
	jne return_liberaMem
	# junta dois blocos consecutivos
	movq 8(%rdi), %r11
	subq %r10, %rdi
	subq $8, %rdi
	addq $16, %r11
	addq %r11, (%rdi)
return_liberaMem:
	addq $16, %rsp
	popq %rbp
	ret
# =========================================================================== #
# Aloca %rdi bytes na heap e retorna o ptr do bloco	em %rax					  #
# =========================================================================== #
alocaMem: # tamanho do bloco
	pushq %rbp
	movq %rsp, %rbp
	subq $64, %rsp # aloca tamanho multiplo de 16 bytes
	movq %r12, -32(%rbp)
	movq %r13, -40(%rbp)
	movq %r14, -48(%rbp)
	movq %r15, -56(%rbp)
	# alocaMem(0)
	movq $0, %rax
	cmpq $0, %rdi
	je return_alocaMem
	movq topoInicialHeap, %r11
	movq topoAtualHeap, %r12
	movq $0x7fffffffffffffff, %r13 # menor
	cmpq %r11, %r12
	jg while_procurar_bloco
	# alocacao do primeiro bloco de 4096
	movq %rdi, -8(%rbp)
	movq %r11, -16(%rbp)
	addq $4096, %r12
	movq %r12, %rdi
	movq $12, %rax
	syscall
	movq -8(%rbp), %rdi
	movq -16(%rbp), %r11
	movq $0, (%r11)
	movq $4080, 8(%r11)
	movq %r11, topoBlocosHeap
while_procurar_bloco:
	cmpq %r12, %r11
	jg fora_while_procurar_bloco
	cmpq $0, (%r11)
	jne fora_bloco_livre
	# bloco esta livre
	cmpq 8(%r11), %rdi
	jne bloco_livre_com_tamanho_diferente
	# bloco encontrado com tamanho igual ao procurado
	movq $1, (%r11)
	movq %r11, %rax
	addq $16, %rax
	jmp return_alocaMem
bloco_livre_com_tamanho_diferente:
	cmpq 8(%r11), %rdi
	jg fora_bloco_com_espaco
	cmpq 8(%r11), %r13 # compara tamanho com menor (r13)
	jle fora_menor_que_menor
	movq 8(%r11), %r13
	movq %r11, %r14 # coloca endereco do bloco menor em r14
fora_menor_que_menor:
fora_bloco_com_espaco:
fora_bloco_livre:
	addq $16, %r11
	movq -8(%r11), %r15
	addq %r15, %r11 # r15 sera usado apos while caso nao encontrar bloco
	jmp while_procurar_bloco
fora_while_procurar_bloco:
	movq $0x7fffffffffffffff, %r15
	cmpq %r15, %r13
	jne fora_bloco_nao_encontrado
	movq %r11, %r14
	subq %r15, %r14
	subq $16, %r14
	cmpq $0, (%r14)
	jne fora_ultimo_livre
	movq 8(%r14), %r15
	jmp while_calcula_brk
fora_ultimo_livre:
	movq $-16, %r15
	movq %r11, %r14
	movq %r14, topoBlocosHeap
	movq %r14, %rax
while_calcula_brk:
	addq $4096, %r12
	addq $4096, %r15
	cmpq %r15, %rdi
	jle fora_while_calcula_brk
	jmp while_calcula_brk
fora_while_calcula_brk:
	movq %rdi, -8(%rbp)
	movq %r11, -16(%rbp)
	movq %r12, %rdi
	movq $12, %rax
	syscall
	movq -8(%rbp), %rdi
	movq -16(%rbp), %rdi
	movq %r15, 8(%r14)
fora_bloco_nao_encontrado:
	movq $1, (%r14)
	movq 8(%r14), %r15
	movq %rdi, 8(%r14)
	subq %rdi, %r15
	cmpq $16, %r15
	jle fora_divide_bloco
	# bloco livre sera partido em dois
	addq $16, %r14
	addq -8(%r14), %r14
	movq $0, (%r14)
	subq $16, %r15
	movq %r15, 8(%r14)
	jmp return_alocaMem
fora_divide_bloco:
	addq %r15, 8(%r14)
return_alocaMem:
	movq %r12, topoAtualHeap
	movq -32(%rbp), %r12
	movq -40(%rbp), %r13
	movq -48(%rbp), %r14
	movq -56(%rbp), %r15
	addq $64, %rsp
	popq %rbp
	ret
# =========================================================================== #
# Imprime um mapa da heap 													  #
# =========================================================================== #
imprimeMapa: # sem parametros
	pushq %rbp
	movq %rsp, %rbp
	subq $16, %rsp # aloca tamanho multiplo de 16 bytes
	movq %r12, -8(%rbp)
	movq topoInicialHeap, %r11
	movq topoAtualHeap, %r12
	cmpq %r11, %r12
	jl return_imprimeMapa
	movq topoInicialHeap, %r10
	movq topoBlocosHeap, %r11
while_imprime:
	movq $16, %r12
while_asterisco:
	movq asterico, %rdi
	call printf
	dec %r12
	cmpq $0, %r12
	je fora_while_asterisco
	jmp while_asterisco
fora_while_asterisco:
	movq 8(%r11), %r12
	cmpq $1, (%r11)
	jne imprime_menos
	movq mais, %rdi
	jmp while_mais_menos
imprime_menos:
	movq menos, %rdi
while_mais_menos:
	cmpq $0, %r12
	je fora_while_mais_menos
	call printf
	dec %r12
	jmp while_mais_menos
fora_while_mais_menos:
	addq $16, %r11
	addq -8(%r11), %r11
	jmp while_imprime
fora_while_imprime:
	movq quebraLinha, %rdi
	call printf
return_imprimeMapa:
	movq -8(%rbp), %r12
	addq $16, %rsp
	popq %rbp
	ret
