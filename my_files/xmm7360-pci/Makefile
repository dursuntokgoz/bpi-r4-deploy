include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=xmm7360
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define KernelPackage/xmm7360
  SUBMENU:=Network Devices
  TITLE:=Fibocom XMM7360 PCI Express driver
  FILES:=$(PKG_BUILD_DIR)/xmm7360.ko
  AUTOLOAD:=$(call AutoProbe,xmm7360)
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

$(eval $(call KernelPackage,xmm7360))
