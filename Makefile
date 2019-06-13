ARCHS = armv7 arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = 13HUD
13HUD_FILES = $(wildcard *.xm *.mm)
13HUD_FRAMEWORKS = UIKit
13HUD_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += 13hud
include $(THEOS_MAKE_PATH)/aggregate.mk
