include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-rpi-fan
PKG_VERSION:=1.1.0
PKG_RELEASE:=1
PKG_LICENSE:=MIT
PKGARCH:=all

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-rpi-fan
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=Raspberry Pi hardware PWM fan control
  DEPENDS:=+luci-base +rpcd +uci +jsonfilter
endef

define Package/luci-app-rpi-fan/conffiles
/etc/config/rpi-fan
endef

define Package/luci-app-rpi-fan/description
 LuCI hardware PWM fan control for Raspberry Pi 3B+ on OpenWrt 25.12.
 GPIO18 / pwmchip0 / pwm0 must already be enabled by a boot overlay.
 Includes automatic temperature control, manual duty, fail-safe cooling,
 UCI configuration, a procd service and read-only ubus status.
endef

define Package/luci-app-rpi-fan/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	/etc/init.d/rpcd restart || exit 1
fi
exit 0
endef

define Build/Configure
endef
define Build/Compile
endef

define Package/luci-app-rpi-fan/install
	$(INSTALL_DIR) $(1)/etc/config $(1)/etc/init.d
	$(INSTALL_CONF) ./root/etc/config/rpi-fan $(1)/etc/config/rpi-fan
	$(INSTALL_BIN) ./root/etc/init.d/rpi-fan $(1)/etc/init.d/rpi-fan
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/usr/lib/rpi-fan $(1)/usr/libexec/rpcd
	$(INSTALL_BIN) ./root/usr/sbin/rpi-fand $(1)/usr/sbin/rpi-fand
	$(INSTALL_DATA) ./root/usr/lib/rpi-fan/control.sh $(1)/usr/lib/rpi-fan/control.sh
	$(INSTALL_BIN) ./root/usr/libexec/rpcd/rpi-fan $(1)/usr/libexec/rpcd/rpi-fan
	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./root/usr/share/luci/menu.d/*.json $(1)/usr/share/luci/menu.d/
	$(INSTALL_DATA) ./root/usr/share/rpcd/acl.d/*.json $(1)/usr/share/rpcd/acl.d/
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view
	$(INSTALL_DATA) ./htdocs/luci-static/resources/view/rpi-fan.js $(1)/www/luci-static/resources/view/rpi-fan.js
endef

$(eval $(call BuildPackage,luci-app-rpi-fan))
