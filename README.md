<p align="center">
<img src="https://github.com/hexagonix/Doc/blob/main/Img/banner.png">
</p>

<div align="center">

![](https://img.shields.io/github/license/hexagonix/Saturno.svg)
![](https://img.shields.io/github/stars/hexagonix/Saturno.svg)
![](https://img.shields.io/github/issues/hexagonix/Saturno.svg)
![](https://img.shields.io/github/issues-closed/hexagonix/Saturno.svg)
![](https://img.shields.io/github/issues-pr/hexagonix/Saturno.svg)
![](https://img.shields.io/github/issues-pr-closed/hexagonix/Saturno.svg)
![](https://img.shields.io/github/downloads/hexagonix/Saturno/total.svg)
![](https://img.shields.io/github/release/hexagonix/Saturno.svg)
[![](https://img.shields.io/twitter/follow/hexagonixOS.svg?style=social&label=Follow%20%40HexagonixOS)](https://twitter.com/hexagonixOS)

</div>

<img src="https://github.com/hexagonix/Doc/blob/main/Img/hr.png" width="100%" height="2px" />

# Saturno

<details title="Português (Brasil)" align='left'>
<br>
<summary align='left'>🇧🇷 Português (Brasil)</summary>

<div align="justify">

# Inicialização do Hexagon

Este repositório contém o gerenciador de inicialização MBR do Hexagonix e o Hexagon Boot, responsável por carregar, configurar e executar o Hexagon, bem como oferecer outros recursos.

## Saturno

O primeiro componente do Hexagonix é o Saturno. Ele é responsável por receber o controle do processo de inicialização realizado pelo BIOS/UEFI e procurar no volume o segundo estágio de inicialização. Para isso, ele implementa um driver para leitura de um sistema de arquivos FAT16. O segundo estágio de inicialização (HBoot) pode implementar drivers para outros sistemas de arquivos e é responsável por encontrar o Hexagon, carregar módulos HBoot ou carregar um sistema do tipo DOS compatível (versão BETA).

### Sistemas de arquivos suportados

* FAT16B

</div>

</details>

<details title="English" align='left'>
<br>
<summary align='left'>🇬🇧 English</summary>

<div align="justify">

# Hexagon initialization

This repository contains the Hexagonix MBR boot manager and Hexagon Boot, which is responsible for loading, configuring, and running Hexagon, as well as offering other features.

## Saturno

The first component of Hexagonix is Saturno. It is responsible for taking control of the boot process performed by the BIOS/UEFI and looking in the volume for the second boot stage. For that, it implements a driver for reading a FAT16 file system. The second boot stage (HBoot) can implement drivers for other file systems and is responsible for finding Hexagon, loading HBoot modules or loading a compatible DOS-type system (BETA version).

### Supported file systems

* FAT16B

</div>

</details>

<!--

Versão deste arquivo: 2.0

-->
