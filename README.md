# BIOS Text Editor (Two-Stage Bootloader)

A minimal **two-stage boot sector program** written in **x86 assembly** that implements a bare-metal text editor.  
The editor supports typing, saving, and loading text directly from **video memory** — running entirely without an operating system.

---

## ✨ Features
- **Two-stage bootloader**
  - Stage 1 fits within the 512-byte MBR limit
  - Loads Stage 2 into memory to enable editor functionality
- **Text editor**
  - Character input with real-time screen updates
  - Save and load text buffers from video memory
- **Low-level system design**
  - Direct manipulation of VGA text mode memory
  - BIOS interrupt handling
  - Demonstrates bare-metal control transfer between boot stages

---

## 🛠️ Requirements
- An x86 emulator such as:
  - [QEMU](https://www.qemu.org/)  
  - [Bochs](http://bochs.sourceforge.net/)  
  - Or real hardware (bootable image on USB)
- `nasm` assembler to build the project

---

## 🚀 Build & Run

### Build
```bash
nasm -f bin stage1.asm -o stage1.bin
nasm -f bin stage2.asm -o stage2.bin
cat stage1.bin stage2.bin > editor.img
qemu-system-i386 -fda editor.img
```
