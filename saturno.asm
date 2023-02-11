;;************************************************************************************
;;
;;    
;; ┌┐ ┌┐                                 Sistema Operacional Hexagonix®
;; ││ ││
;; │└─┘├──┬┐┌┬──┬──┬──┬─┐┌┬┐┌┐    Copyright © 2015-2023 Felipe Miguel Nery Lunkes
;; │┌─┐││─┼┼┼┤┌┐│┌┐│┌┐│┌┐┼┼┼┼┘          Todos os direitos reservados
;; ││ │││─┼┼┼┤┌┐│└┘│└┘││││├┼┼┐
;; └┘ └┴──┴┘└┴┘└┴─┐├──┴┘└┴┴┘└┘
;;              ┌─┘│                 Licenciado sob licença BSD-3-Clause
;;              └──┘          
;;
;;
;;************************************************************************************
;;
;; Este arquivo é licenciado sob licença BSD-3-Clause. Observe o arquivo de licença 
;; disponível no repositório para mais informações sobre seus direitos e deveres ao 
;; utilizar qualquer trecho deste arquivo.
;;
;; BSD 3-Clause License
;;
;; Copyright (c) 2015-2023, Felipe Miguel Nery Lunkes
;; All rights reserved.
;; 
;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions are met:
;; 
;; 1. Redistributions of source code must retain the above copyright notice, this
;;    list of conditions and the following disclaimer.
;;
;; 2. Redistributions in binary form must reproduce the above copyright notice,
;;    this list of conditions and the following disclaimer in the documentation
;;    and/or other materials provided with the distribution.
;;
;; 3. Neither the name of the copyright holder nor the names of its
;;    contributors may be used to endorse or promote products derived from
;;    this software without specific prior written permission.
;; 
;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
;; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
;; DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
;; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
;; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
;; SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
;; CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
;; OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
;; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;;
;; $HexagonixOS$

;;************************************************************************************
;;
;;                               Saturno® versão 1.6A
;;
;;                   Carregador de Inicialização do Kernel Hexagon®
;;
;;      Carrega o segundo estágio de inicialização, Hexagon Boot (HBoot) no disco
;;
;;************************************************************************************

use16                   

    jmp short iniciarHBoot
            
    nop 

;;************************************************************************************

;; BIOS Parameter Block (BPB)
;; Necessário para a identificação do disco        

;;************************************************************************************
                                                        
BPB:

NomeOEM:            db 'HEXAGON '    ;; Nome OEM
bytesPorSetor:      dw 512           ;; Número de bytes em cada setor
setoresPorCluster:  db 8             ;; Setores por cluster
setoresReservados:  dw 16            ;; Setores reservados após o setor de inicialização
totalFATs:          db 2             ;; Número de tabelas FAT
entradasRaiz:       dw 512           ;; Número total de pastas e arquivos no diretório raiz
pequenosSetores:    dw 0             ;; Número total de pequenos setores no disco
tipoMedia:          db 0xf8          ;; Tipo de media. 0xf8 para discos rígidos
setoresPorFAT:      dw 16            ;; Setores usados na FAT
setoresPorTrilha:   dw 63            ;; Total de setores em uma trilha
totalCabecas:       dw 255           ;; Número de cabeças de leitura no disco
setoresOcultos:     dd 0             ;; Número de setores antes do início do volume (encontrar diretório raiz)
totalSetores:       dd 92160         ;; Tamanho do disco. Aproximadamente 45 Mb
numDrive:           db 0x80          ;; Número de identificação do drive. 0x80 para discos rígidos 
                    db 0             ;; Reservado
assinaturaDisco:    db 0             ;; Assinatura do disco
IDVolume:           dd 0             ;; Qualquer número
rotuloVolume:       db 'HEXAGONIX  ' ;; Um nome de 11 caracteres para o disco
sistemaArquivos:    db 'FAT16   '    ;; Nome do sistema de arquivos utilizado no disco

;;************************************************************************************

SEG_BOOT        equ 0x2000 ;; Segmento para realocar carregador de inicialização
SEG_HBOOT       equ 0x1000 ;; Segmento para carregar Kernel
CABECALHO_HBOOT = 10h      ;; Tamanho do cabeçalho do HBoot (versão 2.0 do cabaçalho)

iniciarHBoot:

;; Configurar pilha e ponteiro

    cli                ;; Desativar interrupções
    
    mov ax, 0x5000
    mov ss, ax
    mov sp, 0
    
    sti                ;; Habilitar interrupções

;; Salvar entedereço LBA da partição

    mov ebp, dword[si+8] ;; Endereço LBA da partição

    push ebp

;; Localizado entre 0x7c00 e 0x20000

    mov ax, 0
    mov ds, ax
    mov ax, SEG_BOOT
    mov es, ax

    cli
    
    cld                 ;; Limpar direção
    
    mov si, 0x7c00      ;; Fonte (DS:SI)
    mov di, 0           ;; Destino (ES:DI)
    mov ecx, 512        ;; Total de bytes para mover
    
    rep movsb

    jmp SEG_BOOT:inicio ;; Carregar novo CS e IP

;; Início da execução em 0x20000

inicio:
    
;; Carregar registradores de segmento para a nova posição
    
    mov ax, SEG_BOOT
    mov ds, ax
    mov es, ax
    
    sti

    mov byte[numDrive], dl ;; Salvar número do drive

;; Calcular o tamanho do diretório raiz
;; 
;; Fórmula:
;;
;; Tamanho  = (entradasRaiz * 32) / bytesPorSetor

    mov ax, word[entradasRaiz]
    shl ax, 5           ;; Multiplicar por 32
    mov bx, word[bytesPorSetor]
    xor dx, dx          ;; DX = 0
    
    div bx              ;; AX = AX / BX
    
    mov word[tamanhoRaiz], ax ;; Salvar tamanho do diretório raiz

;; Calcular o tamanho das tabelas FAT   
;;
;; Fórmula:
;; Tamanho  = totalFATs * setoresPorFAT

    mov ax, word[setoresPorFAT]
    movzx bx, byte[totalFATs]
    xor dx, dx                ;; DX = 0
    
    mul bx                    ;; AX = AX * BX
    
    mov word[tamanhoFATs], ax ;; Salvar tamanho das FATs

;; Calcular todos os setores reservados
;;
;; Fórmula:
;;
;; setoresReservados + LBA da partição

    add word[setoresReservados], bp ;; BP é o LBA da partição
    
;; Calcular o endereço da área de dados
;;
;; Fórmula:
;;
;; setoresReservados + tamanhoFATs + tamanhoRaiz

    movzx eax, word[setoresReservados]  
    
    add ax, word[tamanhoFATs]
    add ax, word[tamanhoRaiz]
    
    mov dword[areaDeDados], eax
    
;; Calcular o endereço LBA do diretório raiz e o carregar
;;
;; Fórmula:
;; 
;; LBA  = setoresReservados + tamanhoFATs

    movzx esi, word[setoresReservados]
    
    add si, word[tamanhoFATs]

    mov ax, word[tamanhoRaiz]
    mov di, bufferDeDisco
        
    call carregarSetor

;; Procurar no diretório raiz a entrada do arquivo para o carregar

    mov cx, word[entradasRaiz]
    mov bx, bufferDeDisco

    cld                 ;; Limpar direção
    
loopEncontrarArquivo:

;; Encontrar o nome de 11 caracteres do arquivo em uma entrada

    xchg cx, dx         ;; Salvar contador de loop
    mov cx, 11
    mov si, nomeHBoot
    mov di, bx
    
    rep cmpsb           ;; Comparar (ECX) caracteres entre DI e SI
    
    je arquivoEncontrado

    add bx, 32          ;; Ir para a próxima entrada do diretório raiz (+ 32 bytes)
    
    xchg cx, dx         ;; Restaurar contador
    
    loop loopEncontrarArquivo

;; O arquivo executável do Kernel não foi encontrado. Exibir mensagem de erro e finalizar.

    pop ebp

    mov si, naoEncontrado
    
    call imprimir
    
    jmp $

arquivoEncontrado:

    mov si, word[bx+26]     
    mov word[cluster], si ;; Salvar primeiro cluster

;; Carregar FAT na memória para encontrar todos os clusters do arquivo

    mov ax, word[setoresPorFAT]     ;; Total de setores para carregar
    mov si, word[setoresReservados] ;; LBA
    mov di, bufferDeDisco           ;; Buffer para onde os dados serão carregados

    call carregarSetor

;; Calcular o tamanho do cluster em bytes
;;
;; Fórmula:
;;
;; setoresPorCluster * bytesPorSetor

    movzx eax, byte[setoresPorCluster]
    movzx ebx, word[bytesPorSetor]
    xor edx, edx
        
    mul ebx                 ;; AX = AX * BX 
    
    mov ebp, eax            ;; Salvar tamanho do cluster
    
    mov ax, SEG_HBOOT       ;; Segmento de carregamento do Kernel
    mov es, ax
    mov edi, 0              ;; Buffer para carregar o Kernel

;; Encontrar cluster e carregar cadeia de clusters

loopCarregarClusters:

;; Converter endereço lógico de um cluster para endereço LBA (endereço físico)
;;
;; Fórmula:
;; 
;; ((cluster - 2) * setoresPorCluster) + areaDeDados
 
    movzx esi, word[cluster]    
        
    sub esi, 2

    movzx ax, byte[setoresPorCluster]       
    xor edx, edx         ;; DX = 0
    
    mul esi              ;; (cluster - 2) * setoresPorCluster
    
    mov esi, eax    

    add esi, dword[areaDeDados]

    movzx ax, byte[setoresPorCluster] ;; Total de setores para carregar
    
    call carregarSetor
    
;; Encontrar próximo setor na tabela FAT

    mov bx, word[cluster]
    shl bx, 1                   ;; BX * 2 (2 bytes na entrada)
    
    add bx, bufferDeDisco       ;; Localização da FAT

    mov si, word[bx]            ;; SI contêm o próximo cluster

    mov word[cluster], si       ;; Salvar isso

    cmp si, 0xFFF8              ;; 0xFFF8 é fim de arquivo (EOF)
    jae finalizado

;; Adicionar espaço para o próximo cluster
    
    add edi, ebp                ;; EBP tem o tamanho do cluster
    
    jmp loopCarregarClusters

finalizado:

.executarHBoot:
    
    mov esi, BPB + (SEG_BOOT * 16)  ;; Apontar EBP para BIOS Parameter Block
    pop ebp
    mov dl, byte[numDrive]          ;; Drive utilizado para a inicialização

;; HBoot tem um cabeçalho, então devemos pulá-lo para a execução

    jmp SEG_HBOOT:CABECALHO_HBOOT ;; Configurar CS:IP e executar HBoot

;;************************************************************************************

;;************************************************************************************
;;
;; Variáveis e constantes utilizadas 
;;
;;************************************************************************************
    
cluster:          dw 0
naoEncontrado:    db "HBoot nao encontrado!", 0
erroDisco:        db "Erro de disco!", 0 ;; Mensagem de erro no disco  
nomeHBoot:        db "HBOOT      "       ;; Nome do arquivo que contém o HBoot, a ser carregado

tamanhoRaiz:      dw 0 ;; Tamanho do diretório raiz (em setores)
tamanhoFATs:      dw 0 ;; Tamanho das tabelas FAT (em setores)
areaDeDados:      dd 0 ;; Endereço físico da área de dados (LBA)
enderecoParticao: dd 0

;;************************************************************************************

;; Função para imprimir string em modo real
;;
;; Entrada:
;;
;; SI - String

imprimir:

    lodsb       ;; mov AL, [SI] & inc SI
    
    or al, al   ;; cmp AL, 0
    jz .pronto
    
    mov ah, 0Eh
    
    int 10h     ;; Enviar [SI] para a tela
    
    jmp imprimir
    
.pronto: 

    ret

;;************************************************************************************

;; Carregar setor do disco de boot atual
;;
;; Entrada:
;;
;; AX  - Total de setores para carregar
;; ESI - Endereço LBA  
;; ES:DI - Localização do destino

carregarSetor:

    push si

    mov word[Saturno.Disco.totalSetores], ax
    mov dword[Saturno.Disco.LBA], esi
    mov word[Saturno.Disco.segmento], es
    mov word[Saturno.Disco.deslocamento], di

    mov dl, byte[numDrive]
    mov si, Saturno.Disco
    mov ah, 0x42        ;; Função de leitura
    
    int 13h             ;; Serviços de disco do BIOS
    
    jnc .concluido          

;; Se ocorrerem erros no disco, exibir mensagem de erro na tela

    mov si, erroDisco   
    
    call imprimir
    
    jmp $

.concluido:
    
    pop si
    
    ret
    
;;************************************************************************************
    
Saturno.Disco:

.tamanho:       db 16
.reservado:     db 0
.totalSetores:  dw 0
.deslocamento:  dw 0x0000
.segmento:      dw 0
.LBA:           dd 0
                dd 0

;;************************************************************************************
                
TIMES 510-($-$$) db 0      ;; O arquivo deve ter exatos 512 bytes

assinaturaBoot:  dw 0xAA55 ;; Disco inicializável

;; O arquivo será carregado no espaço abaixo

bufferDeDisco: 
