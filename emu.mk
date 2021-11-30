IMG ?= emulator2

X_GPU ?= -gpu swiftshader_indirect

all: 

all-local::
	emulator/emulator @$(IMG) $(X_GPU)

