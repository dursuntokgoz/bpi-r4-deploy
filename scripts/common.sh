# Build steps shared by both boards, sourced by build.sh.
# $REPO is the repository root; the steps after fetch_sources and
# add_kernel_patches run inside $REPO/openwrt.

# Read pins.conf; a value already in the environment wins.
load_pins() {
	local key value
	while IFS='=' read -r key value; do
		case $key in ''|\#*) continue ;; esac
		[ -n "${!key:-}" ] || export "$key=$value"
	done < "$1"
}

fetch_sources() {
	rm -rf openwrt mtk-openwrt-feeds

	git clone --branch openwrt-25.12 https://github.com/openwrt/openwrt.git openwrt
	git -C openwrt checkout "$OPENWRT_COMMIT"

	git clone --branch main https://github.com/mediatek/mtk-openwrt-feeds mtk-openwrt-feeds
	git -C mtk-openwrt-feeds checkout "$MTK_COMMIT"
}

# Kernel patches for both boards go into the MTK feed, so the autobuild
# prepare step puts them next to MediaTek's own.
add_kernel_patches() {
	\cp "$REPO"/common/patches/kernel/*.patch \
		mtk-openwrt-feeds/25.12/files/target/linux/mediatek/patches-6.12/
}

# Since MTK feed c21f3b36 mt76/mac80211/hostapd come from
# github.com/mediatek/softmac_* and the feed has no patch directories for
# them any more. Pin the sources, then add our patches straight into the
# packages. Each board lists the patches it takes in WIFI_PATCHES.
add_wifi_patches() {
	local p dir

	sh "$REPO/common/softmac-pin.sh"
	mkdir -p package/kernel/mt76/patches package/kernel/mac80211/patches/subsys \
		package/network/services/hostapd/patches
	for p in $WIFI_PATCHES; do
		case $p in
		mt76/*)     dir=package/kernel/mt76/patches ;;
		mac80211/*) dir=package/kernel/mac80211/patches/subsys ;;
		hostapd/*)  dir=package/network/services/hostapd/patches ;;
		esac
		\cp "$REPO/common/patches/wifi/$p" "$dir/"
	done
}

# Patches both boards take from common/patches: the U-Boot NVMe/NAND/MMC
# support and the NVMe DT overlay and fitblk boot.
add_common_tree_patches() {
	\cp "$REPO"/common/patches/uboot/*.patch package/boot/uboot-mediatek/patches/
	\cp "$REPO"/common/patches/target/*.patch target/linux/mediatek/patches-6.12/
}

add_packages() {
	if [ -d "$REPO/common/packages/kmod-iosm-custom" ]; then
		mkdir -p package/kernel/iosm-custom
		\cp -r "$REPO/common/packages/kmod-iosm-custom/." package/kernel/iosm-custom/
	fi
	\cp -r "$REPO/common/packages/sms-tool/" feeds/packages/utils/sms-tool
	\cp -r "$REPO/common/packages/modemdata-main/" feeds/packages/utils/modemdata
	\cp -r "$REPO/common/packages/luci-app-modemdata-main/luci-app-modemdata/" feeds/luci/applications
	\cp -r "$REPO/common/packages/luci-app-lite-watchdog/" feeds/luci/applications
	\cp -r "$REPO/common/packages/luci-app-sms-tool-js-main/luci-app-sms-tool-js/" feeds/luci/applications
}

# Files baked into the image: common/files, then the board's files on top.
add_files() {
	mkdir -p files
	\cp -R "$REPO/common/files/." files/
	\cp -R "$REPO/boards/$BOARD/files/." files/
	chmod +x files/usr/bin/* 2>/dev/null || true
}

add_after_feeds() {
	\cp "$REPO/boards/$BOARD/fit.sh" package/utils/fitblk/files/fit.sh

	\cp -r "$REPO/common/qmi.sh" package/network/utils/uqmi/files/lib/netifd/proto/
	chmod -R 755 package/network/utils/uqmi/files/lib/netifd/proto
	chmod -R 755 feeds/luci/applications/luci-app-modemdata/root
	chmod -R 755 feeds/luci/applications/luci-app-sms-tool-js/root
	chmod -R 755 feeds/packages/utils/modemdata/files/usr/share
}

add_config() {
	echo "CONFIG_PACKAGE_trusted-firmware-a-mt7988-emmc-comb-4bg=y" >> .config
	echo "CONFIG_PACKAGE_trusted-firmware-a-mt7988-sdmmc-comb-4bg=y" >> .config
	echo "CONFIG_PACKAGE_trusted-firmware-a-mt7988-spim-nand-ubi-comb-4bg=y" >> .config

	# Fibocom L850-GL / Intel XMM7360 LTE modem support
	echo "CONFIG_PACKAGE_kmod-iosm-custom=y" >> .config
	echo "CONFIG_PACKAGE_kmod-wwan=y" >> .config
	echo "CONFIG_PACKAGE_python3=y" >> .config
	echo "CONFIG_PACKAGE_python3-light=y" >> .config

	# Turkish (tr) translations for LuCI
	echo "CONFIG_LUCI_LANG_tr=y" >> .config

	# Extra management, diagnostic, storage & serial console tools
	echo "CONFIG_PACKAGE_luci-ssl=y" >> .config
	echo "CONFIG_PACKAGE_openssh-sftp-server=y" >> .config
	echo "CONFIG_PACKAGE_nano=y" >> .config
	echo "CONFIG_PACKAGE_nvme-cli=y" >> .config
	echo "CONFIG_PACKAGE_smartmontools=y" >> .config
	echo "CONFIG_PACKAGE_watchcat=y" >> .config
	echo "CONFIG_PACKAGE_luci-app-watchcat=y" >> .config
	echo "CONFIG_PACKAGE_vnstat2=y" >> .config
	echo "CONFIG_PACKAGE_luci-app-vnstat2=y" >> .config
	echo "CONFIG_PACKAGE_mtr-json=y" >> .config
	echo "CONFIG_PACKAGE_bind-dig=y" >> .config
	echo "CONFIG_PACKAGE_zram-swap=y" >> .config
	echo "CONFIG_PACKAGE_usb-modeswitch=y" >> .config
	echo "CONFIG_PACKAGE_picocom=y" >> .config
	echo "CONFIG_PACKAGE_minicom=y" >> .config
	echo "CONFIG_PACKAGE_screen=y" >> .config
}
