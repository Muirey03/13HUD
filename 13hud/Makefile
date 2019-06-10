include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = 13HUD
13HUD_FILES = HDDRootListController.m
13HUD_INSTALL_PATH = /Library/PreferenceBundles
13HUD_FRAMEWORKS = UIKit
13HUD_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/13HUD.plist$(ECHO_END)
