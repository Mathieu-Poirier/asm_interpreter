# Makefile

NASM         := nasm
DD           := dd
SECTOR       := 512
FLOPPY_SECS  := 2880    # 1.44 MB floppy

ASM_BOOT     := boot.asm
ASM_STAGE2   := stage2.asm

BIN_BOOT     := boot.bin
BIN_STAGE2   := stage2.bin
IMG          := floppy.img

.PHONY: all clean run run-nographic

all: $(IMG)

# -----------------------------------------------------------------------------
# 1) Assemble
# -----------------------------------------------------------------------------
$(BIN_BOOT): $(ASM_BOOT)
	$(NASM) -f bin $< -o $@

$(BIN_STAGE2): $(ASM_STAGE2)
	$(NASM) -f bin $< -o $@

# -----------------------------------------------------------------------------
# 2) Create floppy image (depends on both .bin files)
# -----------------------------------------------------------------------------
$(IMG): $(BIN_BOOT) $(BIN_STAGE2)
	# 2.1 zero out a blank image
	$(DD) if=/dev/zero of=$@ bs=$(SECTOR) count=$(FLOPPY_SECS)
	# 2.2 write bootloader into sector 0
	$(DD) if=$(BIN_BOOT)  of=$@ bs=$(SECTOR) seek=0 conv=notrunc
	# 2.3 write stage2 into sectors 1–2
	$(DD) if=$(BIN_STAGE2) of=$@ bs=$(SECTOR) seek=1 conv=notrunc

# -----------------------------------------------------------------------------
# 3) Quick QEMU runner
# -----------------------------------------------------------------------------
run: $(IMG)
	qemu-system-x86_64 -drive if=floppy,format=raw,file=$(IMG)

# -----------------------------------------------------------------------------
# 4) Nographic QEMU runner with TTY passthrough
# -----------------------------------------------------------------------------
run-nographic: $(IMG)
	qemu-system-x86_64 -drive if=floppy,format=raw,file=$(IMG) -nographic

# -----------------------------------------------------------------------------
# 5) Cleanup
# -----------------------------------------------------------------------------
clean:
	-rm -f $(BIN_BOOT) $(BIN_STAGE2) $(IMG)



