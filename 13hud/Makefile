GO_EASY_ON_ME=1

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = 13HUD
13HUD_FILES = HDDRootListController.m
13HUD_INSTALL_PATH = /Library/PreferenceBundles
13HUD_FRAMEWORKS = UIKit Preferences
13HUD_LDFLAGS += -F../Frameworks/

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/13HUD.plist$(ECHO_END)
