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
;;                             Saturno version 1.9.0
;;
;;                      Hexagonix Boot Loader - first stage
;;
;;            Loads the second boot stage, Hexagon Boot (HBoot) to disk
;;
;;************************************************************************************

use16

SEG_BOOT     equ 0x2000 ;; Segment to relocate bootloader
SEG_HBOOT    equ 0x1000 ;; Segment to load HBoot
HBOOT_HEADER = 10h      ;; HBoot header size (header version 2.0)

;;************************************************************************************

entryPoint:

    jmp short startSaturno

    nop

;;************************************************************************************
;;
;; BIOS Parameter Block (BPB)
;; Required for disk identification
;;
;;************************************************************************************

BPB:

OEMName:           db 'HEXAGON '    ;; OEM name
bytesPerSector:    dw 512           ;; Number of bytes in each sector
sectorsPerCluster: db 8             ;; Sectors per cluster
reservedSectors:   dw 16            ;; Reserved sectors after the boot sector
totalFATs:         db 2             ;; Number of FAT tables
rootEntries:       dw 512           ;; Total number of folders and files in the root directory
smallSectors:      dw 0             ;; Total number of small sectors on the disk
mediaType:         db 0xF8          ;; Media type. 0xF8 for hard drives
sectoresPerFAT:    dw 16            ;; Sectors used in FAT
sectoresPerTrack:  dw 63            ;; Total sectors in a track
headNumber:        dw 255           ;; Number of read heads on the disk
hiddenSectors:     dd 0             ;; Number of sectors before the start of the volume (find root directory)
totalSectors:      dd 92160         ;; Disk size. Approximately 45 Mb
numDrive:          db 0x80          ;; Drive identification number. 0x80 for hard drives
reserved:          db 0             ;; Reserved
diskSignature:     db 0             ;; Disk signature
volumeId:          dd 0             ;; Volume identification number
volumeLabel:       db 'HEXAGONIX  ' ;; An 11-character name for the disk
fileSystemName:    db 'FAT16   '    ;; Name of the file system used on the disk

;;************************************************************************************

startSaturno:

;; Configure stack and pointer

    cli ;; Disable interrupts

    mov ax, 0x5000
    mov ss, ax
    mov sp, 0

    sti ;; Enable interrupts

;; Store partition LBA address

    mov ebp, dword[si+8] ;; Partition LBA address

    push ebp

;; Located between 0x7C00 and 0x20000

    mov ax, 0
    mov ds, ax
    mov ax, SEG_BOOT
    mov es, ax

    cli

    cld ;; Clear direction

    mov si, 0x7c00 ;; Source (DS:SI)
    mov di, 0 ;; Destination (ES:DI)
    mov ecx, 512 ;; Total bytes to move

    rep movsb

    jmp SEG_BOOT:start ;; Load new CS and IP

;; Start of execution at 0x20000

start:

;; Load segment registers to new position

    mov ax, SEG_BOOT
    mov ds, ax
    mov es, ax

    sti

    mov byte[numDrive], dl ;; Save drive number

;; Calculate root directory size
;;
;; Formula:
;;
;; Size = (rootEntries * 32) / bytesPerSector

    mov ax, word[rootEntries]
    shl ax, 5 ;; Multiply by 32
    mov bx, word[bytesPerSector]
    xor dx, dx ;; DX = 0

    div bx ;; AX = AX / BX

    mov word[rootSize], ax ;; Save root directory size

;; Calculate the size of FAT tables
;;
;; Formula:
;;
;; Size = totalFATs * sectorsPerFAT

    mov ax, word[sectoresPerFAT]
    movzx bx, byte[totalFATs]
    xor dx, dx ;; DX = 0

    mul bx ;; AX = AX * BX

    mov word[sizeFATs], ax ;; Save FAT size

;; Calculate all reserved sectors
;;
;; Formula:
;;
;; reservedSectors + partition LBA

    add word[reservedSectors], bp ;; BP is the LBA of the partition

;; Calculate data area address
;;
;; Formula:
;;
;; reservedSectors + sizeFATs + rootSize

    movzx eax, word[reservedSectors]

    add ax, word[sizeFATs]
    add ax, word[rootSize]

    mov dword[dataArea], eax

;; Calculate the LBA address of the root directory and load it
;;
;; Formula:
;;
;; LBA = reservedSectors + sizeFATs

    movzx esi, word[reservedSectors]

    add si, word[sizeFATs]

    mov ax, word[rootSize]
    mov di, diskBuffer

    call loadSector

;; Search the root directory for the file entry to load it

    mov cx, word[rootEntries]
    mov bx, diskBuffer

    cld ;; Clear direction

findFileLoop:

;; Finding the 11-character file name in an entry

    xchg cx, dx ;; Save loop counter
    mov cx, 11
    mov si, HBootFilename
    mov di, bx

    rep cmpsb ;; Compare (ECX) characters between DI and SI

    je fileFound

    add bx, 32 ;; Go to the next root directory entry (+32 bytes)

    xchg cx, dx ;; Restore counter

    loop findFileLoop

;; The HBoot executable file was not found. Display error message and finish

    pop ebp

    mov si, HBootNotFound

    call printString

    jmp $

fileFound:

    mov si, word[bx+26]
    mov word[cluster], si ;; Save first cluster

;; Load FAT into memory to find all clusters of the file

    mov ax, word[sectoresPerFAT] ;; Total sectors to load
    mov si, word[reservedSectors] ;; LBA
    mov di, diskBuffer ;; Buffer where data will be loaded

    call loadSector

;; Calculate cluster size in bytes
;;
;; Formula:
;;
;; sectorsPerCluster * bytesPerSector

    movzx eax, byte[sectorsPerCluster]
    movzx ebx, word[bytesPerSector]
    xor edx, edx

    mul ebx ;; AX = AX * BX

    mov ebp, eax ;; Save cluster size

    mov ax, SEG_HBOOT ;; HBoot loading segment
    mov es, ax
    mov edi, 0 ;; Buffer to load HBoot

;; Find cluster and load cluster chain

loadClustersLoop:

;; Convert a cluster's logical address to LBA address (physical address)
;;
;; Formula:
;;
;; ((cluster - 2) * sectorsPerCluster) + dataArea

    movzx esi, word[cluster]

    sub esi, 2

    movzx ax, byte[sectorsPerCluster]
    xor edx, edx ;; DX = 0

    mul esi ;; (cluster - 2) * sectorsPerCluster

    mov esi, eax

    add esi, dword[dataArea]

    movzx ax, byte[sectorsPerCluster] ;; Total sectors to load

    call loadSector

;; Find next sector in FAT table

    mov bx, word[cluster]
    shl bx, 1 ;; BX * 2 (2 bytes on input)

    add bx, diskBuffer ;; FAT location

    mov si, word[bx] ;; SI contain the next cluster

    mov word[cluster], si ;; Store this

    cmp si, 0xFFF8 ;; 0xFFF8 is end of file (EOF)
    jae finished

;; Add space for the next cluster

    add edi, ebp ;; EBP has the size of the cluster

    jmp loadClustersLoop

finished:

.startHBoot:

    mov esi, BPB + (SEG_BOOT * 16) ;; Point EBP to BIOS Parameter Block
    pop ebp
    mov dl, byte[numDrive] ;; Drive used for boot

;; HBoot has a header so we should skip it for execution

    jmp SEG_HBOOT:HBOOT_HEADER ;; Configure CS:IP and run HBoot

;;************************************************************************************

;; Function for print string in real mode
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

;; Load sector from current boot disk
;;
;; Input:
;;
;; AX    - Total sectors to load
;; ESI   - LBA Address
;; ES:DI - Destination

loadSector:

    push si

    mov word[Saturno.Disk.totalSectors], ax
    mov dword[Saturno.Disk.LBA], esi
    mov word[Saturno.Disk.segment], es
    mov word[Saturno.Disk.offset], di

    mov dl, byte[numDrive]
    mov si, Saturno.Disk
    mov ah, 0x42 ;; Read function

    int 13h ;; BIOS Disk Services

    jnc .done

;; If disk errors occur, display error message on screen

    mov si, diskError

    call printString

    jmp $

.done:

    pop si

    ret

;;************************************************************************************

;;************************************************************************************
;;
;; Variables and constants used
;;
;;************************************************************************************

HBootNotFound:
db "HBoot not found!", 0
diskError: ;; Disk error message
db "HBoot: Disk error!", 0
HBootFilename: ;; Name of the file containing HBoot, to be loaded
db "HBOOT      "

cluster:  dw 0
rootSize: dw 0 ;; Root directory size (in sectors)
sizeFATs: dw 0 ;; Size of FAT tables (in sectors)
dataArea: dd 0 ;; Data area physical address (LBA)

Saturno.Disk:

.size:         db 16
.reserved:     db 0
.totalSectors: dw 0
.offset:       dw 0x0000
.segment:      dw 0
.LBA:          dd 0
               dd 0

;;************************************************************************************

times 510-($-$$) db 0 ;; The file must be exactly 512 bytes

bootSignature: dw 0xAA55 ;; Bootable volume

;;************************************************************************************

;; The file will be uploaded to the space below

diskBuffer:
