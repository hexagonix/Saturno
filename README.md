<p align="center">
<img src="https://github.com/hexagonix/Doc/blob/main/Img/Hexagonix.png" width="150" height="150">
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

</div>

<hr>

# Inicialização do Hexagon

Este repositório contém o gerenciador de inicialização MBR do Hexagonix e o Hexagon Boot, responsável por carregar, configurar e executar o Hexagon, bem como oferecer outros recursos.

## Saturno

O primeiro componente do Hexagonix/Andromeda é o Saturno. Ele é responsável por receber o controle do processo de inicialização realizado pelo BIOS/UEFI e procurar no volume o segundo estágio de inicialização. Para isso, ele implementa um driver para leitura de um sistema de arquivos FAT16. O segundo estágio de inicialização (HBoot) pode implementar drivers para outros sistemas de arquivos e é responsável por encontrar o Hexagon, carregar módulos HBoot ou carregar um sistema do tipo DOS compatível (versão BETA).

### Sistemas de arquivos suportados

* FAT16B

<!--

Versão deste arquivo: 2.0

-->
