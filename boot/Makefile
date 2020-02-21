
.PHONY : clean all rebuild

BOOT_SRC := boot.asm
BOOT_OUT := boot.bin

LOADER_SRC := loader.asm
LOADER_OUT := loader

IMG := boot.img
IMG_PATH := /media/zhu/U

all : $(BOOT_OUT) $(IMG) $(LOADER_OUT)
	dd if=$(BOOT_OUT) of=$(IMG) count=1 bs=512 conv=notrunc
	@echo "Success!"
	
$(BOOT_OUT) : $(BOOT_SRC)
	nasm $^ -o $@
	
$(IMG) : 
	bximage $@ -q -fd -size=1.44
	
$(LOADER_OUT) : $(LOADER_SRC)
	@nasm $^ -o $@
	@mount -o loop $(IMG) $(IMG_PATH)/
	@cp $@ $(IMG_PATH)/$@
	@umount $(IMG_PATH)
	
clean :
	$(RM) $(IMG) $(BOOT_OUT)

rebuild : 
	@$(MAKE) clean
	@$(MAKE) all