include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=iosm-custom
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define KernelPackage/iosm-custom
  SUBMENU:=Network Devices
  TITLE:=Intel IPC over Shared Memory driver (custom)
  FILES:=$(PKG_BUILD_DIR)/iosm.ko
  AUTOLOAD:=$(call AutoLoad,50,iosm)
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
	$(MAKE) -C "$(LINUX_DIR)" \
		$(KERNEL_MAKE_FLAGS) \
		M="$(PKG_BUILD_DIR)" \
		modules
endef

$(eval $(call KernelPackage,iosm-custom))
