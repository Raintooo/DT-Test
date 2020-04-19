
.PHONY : clean all rebuild

BOOT_SRC := boot.asm
BOOT_OUT := boot.bin

LOADER_SRC := loader.asm
INCLUDE_SRC := inc.asm
LOADER_OUT := loader

IMG := boot.img
IMG_PATH := /media/zhu/U

all : $(IMG) $(BOOT_OUT) $(LOADER_OUT)
	@dd if=$(BOOT_OUT) of=$(IMG) count=1 bs=512 conv=notrunc
	@echo "Success!"
	
$(BOOT_OUT) : $(BOOT_SRC)
	@nasm $^ -o $@
	@echo "Compile boot.."
	
$(IMG) : 
	bximage $@ -q -fd -size=1.44
	
$(LOADER_OUT) : $(LOADER_SRC) $(INCLUDE_SRC)
	@echo "Compile loader.."
	@nasm $< -o $@
	@sudo mount -o loop $(IMG) $(IMG_PATH)/
	@sudo cp $@ $(IMG_PATH)/$@
	@sudo umount $(IMG_PATH)/
	
clean :
	$(RM) $(BOOT_OUT) $(LOADER_OUT)

rebuild : 
	@$(MAKE) clean
	@$(MAKE) all