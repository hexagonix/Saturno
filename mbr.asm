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
;;                     Sistema Operacional Hexagonix - Hexagonix Operating System
;;
;;                         Copyright (c) 2015-2024 Felipe Miguel Nery Lunkes
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
;; Copyright (c) 2015-2024, Felipe Miguel Nery Lunkes
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
;;                           MBR-Saturno version 1.2.0
;;
;;                             Hexagonix Boot Loader
;;
;;                                Partition table
;;
;;************************************************************************************

use16

start:

;; Configure stack and pointers

    cli ;; Disable interrupts

    mov ax, 0xffff
    mov ss, ax
    mov sp, 0

    sti ;; Enable interrupts

    mov bx, dx ;; Store drive used for boot

    mov ax, 0
    mov es, ax
    mov ds, ax

;; Located between 0x7C00 and 0x500

    cli

    cld

    mov si, 0x7C00 ;; Source
    mov di, 0x500  ;; Destination
    mov ecx, 512   ;; Size

    rep movsb

    jmp 0x50:configure ;; Load new CS and IP

;; Starting at 0x500

configure:

;; Load segment registers to new location

    mov ax, 0x50
    mov ds, ax

    sti

;; Check if the partition is active and load the boot sector

checkPartition1:

    cmp word[partition1.bootable], 0x80
    jne checkPartition2

    mov di, partition1 ;; Save active partition in DI

    jmp loadBootSector

checkPartition2:

    cmp word[partition2.bootable], 0x80
    jne checkPartition3

    mov di, partition2

    jmp loadBootSector

checkPartition3:

    cmp word[partition3.bootable], 0x80
    jne checkPartition4

    mov di, partition3

    jmp loadBootSector

checkPartition4:

    cmp word[partition4.bootable], 0x80
    jne withoutActivePartition

    mov di, partition4

    jmp loadBootSector

loadBootSector:

    mov eax, dword[di+8] ;; LBA address of the active partition
    mov dword[MBR.Disk.LBA], eax
    mov si, MBR.Disk

    mov ah, 0x42 ;; Load sector

    int 13h ;; BIOS Disk Services

    jnc diskReadOk

;; Print error message

    mov esi, diskErrorMsg

    call printString

    jmp $

;;************************************************************************************

diskReadOk:

;; Load DS:SI for first entry

    mov ax, 0
    mov ds, ax
    lea si, [di+0x500] ;; SI = DI+0x500

    mov dx, bx ;; BX contain the boot drive

    jmp 0x0000:0x7C00

;;************************************************************************************

withoutActivePartition:

    mov si, withoutActivePartitionMsg

    call printString

    jmp $

;;************************************************************************************

;; Function to print string in real mode
;;
;; Input:
;;
;; SI - String

printString:

    lodsb ;; mov AL, [SI] & inc SI

    or al, al ;; cmp AL, 0
    jz .done

    mov ah, 0Eh

    int 10h ;; Send [SI] to screen

    jmp printString

.done:

    ret

;;************************************************************************************

MBR.Disk:

.size:          db 16
.reserved:      db 0
.sectorsToRead: dw 1
.segmentOffset: dd 0x00007C00
.LBA:           dd 0
                dd 0

withoutActivePartitionMsg:
db "No active partitions found on the disk!", 10, 13, 10, 13, 0
diskErrorMsg:
db "Disk error!", 0

;;************************************************************************************

times 0x1BE-($-$$) db 0

partition1:

.bootable:      db 0x80  ;; 0x80 = active (bootable)
.headStart:     db 0
.sectorStart:   db 2
.cylinderStart: db 0
.filesystemId:  db 0x06  ;; 0x06 = FAT16
.lastHead:      db 255
.endSector:     db 255
.endCylinder:   db 255
.LBA:           dd 1     ;; Partition LBA start
.totalSectors:  dd 92160 ;; Partition size – Approximately 45 megabytes

partition2:

.bootable:      db 0x00 ;; Não ativa
.headStart:     db 0
.sectorStart:   db 0
.cylinderStart: db 0
.filesystemId:  db 0x00
.lastHead:      db 0
.endSector:     db 0
.endCylinder:   db 0
.LBA:           dd 0 ;; Partition LBA start
.totalSectors:  dd 0

partition3:

.bootable:      db 0x00
.headStart:     db 0
.sectorStart:   db 0
.cylinderStart: db 0
.filesystemId:  db 0x00
.lastHead:      db 0
.endSector:     db 0
.endCylinder:   db 0
.LBA:           dd 0
.totalSectors:  dd 0

partition4:

.bootable:      db 0x00
.headStart:     db 0
.sectorStart:   db 0
.cylinderStart: db 0
.filesystemId:  db 0x00
.lastHead:      db 0
.endSector:     db 0
.endCylinder:   db 0
.LBA:           dd 0
.totalSectors:  dd 0

;;************************************************************************************

times 510-($-$$) db 0

signature: dw 0xAA55
