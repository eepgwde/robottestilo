# weaves

# For the basic-appium-project
IMG ?= emulator2
# For emma Linux on hyper-v
X_GPU ?= -gpu swiftshader_indirect

USER ?= $(shell id -nu)

SYSU ?= systemctl --user

X_RND ?= $$$$

APPIUM_FLAGS ?= -g appium-$(X_RND).log --log-timestamp --local-timezone --log-no-colors --tmp $(TMPDIR) --suppress-adb-kill-server

H_FLAGS ?= 
H_ ?= hlpr $(H_FLAGS)


.PHONY: emulator all-local clean clean-local site-local view-local

all: view-local

all-local:: site-local adb appium emulator

site-local:
	echo $(X_RND)
	test -n "$(ANDROID_SDK_ROOT)"
	test -d "$(ANDROID_SDK_ROOT)"

adb-server.flag: adb
	touch $@

emulator: adb-server.flag
	nohup emulator/emulator @$(IMG) $(X_GPU) > emulator.log 2>&1 &

clean-appium:
	-pgrep -u $(USER) -fl appium | ( while read i j; do kill $$i && sleep 2; done )

appium: 
	nohup appium $(APPIUM_FLAGS) > /dev/null 2>&1 &

adb:
	adb start-server

adb-kill:
	-adb kill-server
	$(RM) adb-server.flag

clean-local:: 
	-pgrep -u $(USER) -fl emulator | ( while read i j; do kill $$i; done )
	$(MAKE) adb-kill
	-pkill adb
	$(MAKE) clean-local-local

clean-local:: clean-appium

clean-local-local:
	$(RM) $(wildcard app-*.flag)

clean:: clean-local-local
	$(RM) $(wildcard appium-*.log emulator.log adb-server.flag)

## Development activities

app-session.flag:
	$(H_) app session-create
	mv session.json-id $@

# This uses a script in the etc/appium directory
#  make app-init0.flag

app-%.flag: etc/appium/%.sh app-session.flag
	$(H_) adb script $(firstword $+)
	$(H_) adb run > $@

session-live:
	$(H_) app session-isnull
	$(MAKE) clean-local-local

# Launch development tools

inspect:
	nohup appium-i > /dev/null 2>&1 &

studio:
	$(SYSU) start ssnap@android-studio

idea:
	$(SYSU) start ssnap@intellij-idea-community

