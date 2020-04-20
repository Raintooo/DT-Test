
.PHONY : all clean rebuild

KERNEL_SRC := kmain.c screen.c

RM := rm -rf 
CFLAGS := -fno-builtin -fno-stack-protector

KERNEL_ADDR := B000
IMG := DT.OS
IMG_PATH := /media/zhu/U

DIR_DEPS := deps
DIR_EXES := exes
DIR_OBJS := objs

DIRS := $(DIR_DEPS) $(DIR_EXES) $(DIR_OBJS)

BLFUNC_SRC := blfunc.asm
BOOT_SRC   := boot.asm
LOADER_SRC := loader.asm
COMMOM_SRC := common.asm
KENTRY_SRC := kentry.asm

BOOT_OUT    := boot
LOADER_OUT  := loader
KERNER_OUT  := kernel
KENTRY_OUT  := $(DIR_OBJS)/kentry.o

EXE := kernel.out
EXE := $(addprefix $(DIR_EXES)/,$(EXE))

SRCS := $(KERNEL_SRC)
#SRCS := $(wildcard *.c)
OBJS := $(SRCS:.c=.o)
OBJS := $(addprefix $(DIR_OBJS)/, $(OBJS))
DEPS := $(SRCS:.c=.dep)
DEPS := $(addprefix $(DIR_DEPS)/, $(DEPS))


all : $(DIR_OBJS) $(DIR_EXES) $(IMG) $(BOOT_OUT) $(LOADER_OUT) $(KERNER_OUT)
	@echo "Success!"
	
ifeq ("$(MAKECMDGOALS)", "all")
-include $(DEPS)
endif

ifeq ("$(MAKECMDGOALS)", "")
-include $(DEPS)
endif

	
$(BOOT_OUT) : $(BOOT_SRC) $(BLFUNC_SRC)
	@nasm $< -o $@
	@echo "Compile boot.."
	@dd if=$(BOOT_OUT) of=$(IMG) bs=512 count=1 conv=notrunc
	
$(IMG) : 
	bximage $@ -q -fd -size=1.44
	
$(LOADER_OUT) : $(LOADER_SRC) $(COMMOM_SRC) $(BLFUNC_SRC)
	@echo "Compile loader.."
	nasm $< -o $@
	sudo mount -o loop $(IMG) $(IMG_PATH)/
	sudo cp $@ $(IMG_PATH)/$@
	sudo umount $(IMG_PATH)/
	
$(KERNER_OUT) : $(EXE)
	./elf2kobj -c$(KERNEL_ADDR) $^ $@
	@echo "Compile Kernel.."
	sudo mount -o loop $(IMG) $(IMG_PATH)/
	sudo cp $@ $(IMG_PATH)/$@
	sudo umount $(IMG_PATH)/

$(KENTRY_OUT) : $(KENTRY_SRC) $(COMMOM_SRC)
	nasm -f elf $< -o $@
	
$(EXE) : $(KENTRY_OUT) $(OBJS)
	ld -s $^ -o $@ 
	
$(DIR_OBJS)/%.o : %.c
	gcc $(CFLAGS) -c $(filter %.c, $^) -o $@
	
$(DIRS) : 
	mkdir $@
	
	
ifeq ("$(wildcard $(DIR_DEPS))", "")
$(DIR_DEPS)/%.dep : $(DIR_DEPS) %.c
else
$(DIR_DEPS)/%.dep : %.c
endif
	@echo "Creating $@ ..."
	@set -e; \
	$(CC) -MM -E $(filter %.c, $^) | sed 's,\(.*\)\.o[ :]*,objs/\1.o $@ : ,g' > $@	
	
	
clean :
	$(RM) $(BOOT_OUT) $(LOADER_OUT) $(IMG) $(DIRS) $(KERNER_OUT) $(EXE)

rebuild : 
	@$(MAKE) clean
	@$(MAKE) all
	

	