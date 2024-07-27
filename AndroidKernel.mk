KERNEL_OUT := $(TARGET_OUT_INTERMEDIATES)/KERNEL_OBJ
KERNEL_CONFIG := $(KERNEL_OUT)/.config
KERNEL_MODULES_OUT := $(TARGET_ROOT_OUT)/lib/modules

JOBS := $(shell if [ $(cat /proc/cpuinfo | grep processor | wc -l) -gt 8 ]; then echo 8; else echo 4; fi)

ifeq ($(USES_UNCOMPRESSED_KERNEL),true)
TARGET_PREBUILT_KERNEL := $(KERNEL_OUT)/arch/$(TARGET_ARCH)/boot/Image
else
TARGET_PREBUILT_KERNEL := $(KERNEL_OUT)/arch/$(TARGET_ARCH)/boot/zImage
endif

$(KERNEL_OUT):
	@echo "==== Start Kernel Compiling ... ===="


$(KERNEL_CONFIG): kernel/arch/$(TARGET_ARCH)/configs/$(KERNEL_DEFCONFIG)
	echo "KERNEL_OUT = $KERNEL_OUT,  KERNEL_DEFCONFIG = KERNEL_DEFCONFIG"
	mkdir -p $(KERNEL_OUT)
	$(MAKE) ARCH=$(TARGET_ARCH) -C kernel O=../$(KERNEL_OUT) $(KERNEL_DEFCONFIG)

ifeq ($(TARGET_BUILD_VARIANT),user)
DEBUGMODE := BUILD=no
USER_CONFIG := $(TARGET_OUT)/dummy
TARGET_DEVICE_USER_CONFIG := $(PLATDIR)/user_diff_config
TARGET_DEVICE_CUSTOM_CONFIG := device/sprd/$(TARGET_DEVICE)/ProjectConfig.mk
TARGET_DEVICE_LOW_RAM_CONFIG := $(PLATDIR)/low_ram_diff_config
ifeq ($(PRODUCT_RAM),low)
$(USER_CONFIG) : $(KERNEL_CONFIG)
	$(info $(shell ./kernel/scripts/sprd_custom_config_kernel.sh $(KERNEL_CONFIG) $(TARGET_DEVICE_CUSTOM_CONFIG)))
	$(info $(shell ./kernel/scripts/sprd_create_user_config.sh $(KERNEL_CONFIG) $(TARGET_DEVICE_USER_CONFIG)))
	$(info $(shell ./kernel/scripts/sprd_create_user_config.sh $(KERNEL_CONFIG) $(TARGET_DEVICE_LOW_RAM_CONFIG)))
else
$(USER_CONFIG) : $(KERNEL_CONFIG)
	$(info $(shell ./kernel/scripts/sprd_custom_config_kernel.sh $(KERNEL_CONFIG) $(TARGET_DEVICE_CUSTOM_CONFIG)))
	$(info $(shell ./kernel/scripts/sprd_create_user_config.sh $(KERNEL_CONFIG) $(TARGET_DEVICE_USER_CONFIG)))
endif
else
DEBUGMODE := $(DEBUGMODE)
USER_CONFIG  := $(TARGET_OUT)/dummy
TARGET_DEVICE_CUSTOM_CONFIG := device/sprd/$(TARGET_DEVICE)/ProjectConfig.mk
TARGET_DEVICE_LOW_RAM_CONFIG := $(PLATDIR)/low_ram_diff_config
ifeq ($(PRODUCT_RAM),low)
$(USER_CONFIG) : $(KERNEL_CONFIG)
	$(info $(shell ./kernel/scripts/sprd_custom_config_kernel.sh $(KERNEL_CONFIG) $(TARGET_DEVICE_CUSTOM_CONFIG)))
	$(info $(shell ./kernel/scripts/sprd_create_user_config.sh $(KERNEL_CONFIG) $(TARGET_DEVICE_LOW_RAM_CONFIG)))
else
$(USER_CONFIG) : $(KERNEL_CONFIG)
	$(info $(shell ./kernel/scripts/sprd_custom_config_kernel.sh $(KERNEL_CONFIG) $(TARGET_DEVICE_CUSTOM_CONFIG)))
endif
endif

$(TARGET_PREBUILT_KERNEL) : $(KERNEL_OUT) $(USER_CONFIG)  | $(KERNEL_CONFIG)
	$(MAKE) -C kernel O=../$(KERNEL_OUT) ARCH=$(TARGET_ARCH) CROSS_COMPILE=$(CROSS_COMPILE) headers_install
	$(MAKE) -C kernel O=../$(KERNEL_OUT) ARCH=$(TARGET_ARCH) CROSS_COMPILE=$(CROSS_COMPILE) -j${JOBS}
	$(MAKE) -C kernel O=../$(KERNEL_OUT) ARCH=$(TARGET_ARCH) CROSS_COMPILE=$(CROSS_COMPILE) modules
	@-mkdir -p $(KERNEL_MODULES_OUT)
	@-find $(TARGET_OUT_INTERMEDIATES) -name *.ko ! -name mali.ko | xargs -I{} cp {} $(KERNEL_MODULES_OUT)
	@-find $(KERNEL_MODULES_OUT) -name *.ko ! -name mali.ko -exec $(CROSS_COMPILE)strip -d --strip-unneeded {} \;

kernelheader:
	mkdir -p $(KERNEL_OUT)
	$(MAKE) ARCH=$(TARGET_ARCH) -C kernel O=../$(KERNEL_OUT) headers_install
