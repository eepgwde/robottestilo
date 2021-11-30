# weaves

# For the basic-appium-project
IMG ?= emulator2
# For emma Linux on hyper-v
X_GPU ?= -gpu swiftshader_indirect

USER ?= $(shell id -nu)

SYSU ?= systemctl --user

X_RND ?= $$$$

APPIUM_FLAGS ?= -g appium-$(X_RND).log --log-timestamp --local-timezone --log-no-colors --tmp $(TMPDIR) --suppress-adb-kill-server 

.PHONY: emulator all-local clean clean-local site-local view-local

all: view-local

all-local:: site-local adb appium emulator

site-local:
	echo $(X_RND)
	test -n "$(ANDROID_SDK_ROOT)"
	test -d "$(ANDROID_SDK_ROOT)"

emulator:
	nohup emulator/emulator @$(IMG) $(X_GPU) > emulator.log 2>&1 &

clean-appium:
	-pgrep -u $(USER) -fl appium | ( while read i j; do kill $$i && sleep 2; done )

appium: 
	nohup appium $(APPIUM_FLAGS) > /dev/null 2>&1 &

adb:
	adb start-server

clean-local::
	-adb kill-server
	-pgrep -u $(USER) -fl emulator | ( while read i j; do kill $$i; done )

clean-local:: clean-appium

# Launch development tools

studio:
	$(SYSU) start ssnap@android-studio

idea:
	$(SYSU) start ssnap@intellij-idea-community

