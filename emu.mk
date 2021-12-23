 # weaves

# For the basic-appium-project
IMG ?= emulator2

OSTYPE := $(shell uname -o)

# For emma Linux on hyper-v
ifeq ($(strip $(OSTYPE)),Cygwin)
X_GPU ?=
X_KILLR_EMU ?= taskkill /f /t /fi "imagename eq emulator*"
else
X_GPU ?= -gpu swiftshader_indirect
X_KILLR_EMU ?= pgrep -u $(USER) -f emulator
endif


# See Error 1 in the README.md
# You need to start cold.

# X_SNAPSHOT ?= -no-snapshot-load
X_SNAPSHOT ?= 

EMULATOR_ARGS ?= $(X_GPU) $(X_SNAPSHOT)

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
	echo OSTYPE - $(strip $(OSTYPE))
	echo $(X_RND)
	test -n "$(ANDROID_SDK_ROOT)"
	test -d "$(ANDROID_SDK_ROOT)"

adb-server.flag: adb
	touch $@

emulator: adb-server.flag
	nohup emulator/emulator @$(IMG) $(EMULATOR_ARGS) > emulator.log 2>&1 &

clean-appium:
	-pkill -u $(USER) -f appium 

appium: 
	nohup appium $(APPIUM_FLAGS) > /dev/null 2>&1 &

adb:
	adb start-server

adb-kill:
	-adb kill-server
	$(RM) adb-server.flag

clean-local:: 
	-$(X_KILLR_EMU) 
	$(MAKE) adb-kill
	-pkill -u $(USER) -f adb
	$(MAKE) clean-local-local

clean-local:: clean-appium

clean-local-local:
	$(RM) $(wildcard app-*.flag)

clean:: clean-local-local
	$(RM) $(wildcard session.json* session-create.out* badging.lst appium-*.log emulator.log adb-server.flag adb0.sh session-create.out session.json)

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
	$(MAKE) app-init0.flag

# Launch development tools

# Check there is a live session and start the inspector
app-inspect.flag: session-live
	nohup appium-i > /dev/null 2>&1 &
	echo $$! > $@

studio:
	$(SYSU) start ssnap@android-studio

idea:
	$(SYSU) start ssnap@intellij-idea-community

