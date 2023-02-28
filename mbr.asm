;;*************************************************************************************************
;;
;; 88                                                                                88              
;; 88                                                                                ""              
;; 88                                                                                                
;; 88,dPPPba,   ,adPPPba, 8b,     ,d8 ,adPPPPba,  ,adPPPb,d8  ,adPPPba,  8b,dPPPba,  88 8b,     ,d8  
;; 88P'    "88 a8P     88  `P8, ,8P'  ""     `P8 a8"    `P88 a8"     "8a 88P'   `"88 88  `P8, ,8P'   
;; 88       88 8PP"""""""    )888(    ,adPPPPP88 8b       88 8b       d8 88       88 88    )888(     
;; 88       88 "8b,   ,aa  ,d8" "8b,  88,    ,88 "8a,   ,d88 "8a,   ,a8" 88       88 88  ,d8" "8b,   
;; 88       88  `"Pbbd8"' 8P'     `P8 `"8bbdP"P8  `"PbbdP"P8  `"PbbdP"'  88       88 88 8P'     `P8  
;;                                               aa,    ,88                                         
;;                                                "P8bbdP"       
;;
;;                    Sistema Operacional Hexagonix® - Hexagonix® Operating System
;;
;;                          Copyright © 2015-2023 Felipe Miguel Nery Lunkes
;;                        Todos os direitos reservados - All rights reserved.
;;
;;*************************************************************************************************
;;
;; Português:
;; 
;; O Hexagonix e seus componentes são licenciados sob licença BSD-3-Clause. Leia abaixo
;; a licença que governa este arquivo e verifique a licença de cada repositório para
;; obter mais informações sobre seus direitos e obrigações ao utilizar e reutilizar
;; o código deste ou de outros arquivos.
;;
;; English:
;;
;; Hexagonix and its components are licensed under a BSD-3-Clause license. Read below
;; the license that governs this file and check each repository's license for
;; obtain more information about your rights and obligations when using and reusing
;; the code of this or other files.
;;
;;*************************************************************************************************
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
;;                             Saturno® versão 1.0.1 BETA
;;
;;                   Carregador de Inicialização do Kernel Hexagon®
;;
;;                                Tabela de partições 
;;
;;************************************************************************************

use16                   

inicio:

;; Configurar pilha e ponteiros

    cli             ;; Desativar interrupções
    
    mov ax, 0xffff
    mov ss, ax
    mov sp, 0
    
    sti             ;; Habilitar interrupções

    mov bx, dx      ;; Salvar drive utilizado para a inicialização

    mov ax, 0
    mov es, ax
    mov ds, ax

;; Localizado entre 0x7c00 e 0x500
    
    cli
    
    cld
    
    mov si, 0x7c00   ;; Fonte
    mov di, 0x500    ;; Destino
    mov ecx, 512
    
    rep movsb
    
    jmp 0x50:comecar ;; Carregar novo CS e IP

;; Começando em 0x500

comecar:

;; Carregar registradores de segmento para a nova localização
    
    mov ax, 0x50
    mov ds, ax
    
    sti

;; Checar se a partição é ativa e carregar o setor de inicialização


checarParticao1:
    
    cmp word[particao1.bootavel], 0x80
    jne checarParticao2
    
    mov di, particao1 ;; Salvar partição ativa em DI
    
    jmp carregarSetorInicializacao

checarParticao2:

    cmp word[particao2.bootavel], 0x80
    jne checarParticao3
    
    mov di, particao2
    
    jmp carregarSetorInicializacao

checarParticao3:

    cmp word[particao3.bootavel], 0x80
    jne checarParticao4
    
    mov di, particao3
    
    jmp carregarSetorInicializacao

checarParticao4:

    cmp word[particao4.bootavel], 0x80
    jne semParticaoAtiva
    
    mov di, particao4
    
    jmp carregarSetorInicializacao

carregarSetorInicializacao:

    mov eax, dword[di+8] ;; Endereço LBA da partição ativa
    mov dword[PROPRIEDADES_DISCO.LBA], eax
    mov si, PROPRIEDADES_DISCO
    
    mov ah, 0x42         ;; Carregar setor
    
    int 13h              ;; Serviços de disco do BIOS
    
    jnc leituraDiscoOK

;; Imprimir mensagem de erro

    mov esi, msgErroDisco
    
    call imprimir
    
    jmp $
    
;;************************************************************************************
    
leituraDiscoOK:

;; Carregar DS:SI para a primeira entrada

    mov ax, 0
    mov ds, ax
    lea si, [di+0x500]  ;; SI = DI+0x500

    mov dx, bx          ;; BX contêm o drive de boot
    
    jmp 0x0000:0x7c00

;;************************************************************************************
    
semParticaoAtiva:

    mov si, msgSemParticaoAtiva
    
    call imprimir

    jmp $
    
;;************************************************************************************
    
PROPRIEDADES_DISCO:

.tamanho:               db 16
.reservado:             db 0
.setoresParaLer:        dw 1
.deslocamentoSegmento:  dd 0x00007c00
.LBA:                   dd 000
                        dd 0

msgSemParticaoAtiva:    db "Nenhuma particao ativa encontrada no disco!", 10, 13, 10, 13, 0
msgErroDisco:           db "Erro no disco!", 0

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
    
TIMES 0x1BE-($-$$) db 0

particao1:

.bootavel:             db 0x80      ;; 0x80 = ativa (bootável)
.inicioCabeca:         db 0
.setorDeInicio:        db 2 
.cilindroDeInicio:     db 0 
.IDSistemaDeArquivos:  db 0x06      ;; 0x06 = FAT16
.ultimaCabeca:         db 255
.setorFim:             db 255
.cilindroFim:          db 255
.LBA:                  dd 1         ;; Início LBA da partição
.totalSetores:         dd 92160     ;; Tamanho da partição - Aproximadamente 45 megabytes

particao2:

.bootavel:             db 0x00      ;; Não ativa
.inicioCabeca:         db 0
.setorDeInicio:        db 0
.cilindroDeInicio:     db 0 
.IDSistemaDeArquivos:  db 0x00
.ultimaCabeca:         db 0
.setorFim:             db 0
.cilindroFim:          db 0
.LBA:                  dd 0         ;; Início LBA da partição
.totalSetores:         dd 0         ;; Tamanho da partição - Aproximadamente 512 megabytes

particao3:

.bootavel:             db 0x00      
.inicioCabeca:         db 0
.setorDeInicio:        db 0
.cilindroDeInicio:     db 0 
.IDSistemaDeArquivos:  db 0x00
.ultimaCabeca:         db 0
.setorFim:             db 0
.cilindroFim:          db 0
.LBA:                  dd 0     
.totalSetores:         dd 0     

particao4:

.bootavel:             db 0x00
.inicioCabeca:         db 0
.setorDeInicio:        db 0
.cilindroDeInicio:     db 0 
.IDSistemaDeArquivos:  db 0x00
.ultimaCabeca:         db 0
.setorFim:             db 0
.cilindroFim:          db 0
.LBA:                  dd 0     
.totalSetores:         dd 0     
    
;;************************************************************************************
    
TIMES 510-($-$$) db 0

dw 0xAA55
