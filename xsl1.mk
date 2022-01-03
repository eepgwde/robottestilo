# weaves

## Post-process the snapshot pages and categorize

# This supercedes xsl1.mk

.PHONY: all-local view-local install-local

O_DIR?=cache

S_DIR ?= appium-boilerplate/pages
T_DIR ?= $(S_DIR)/../tests/resources
HLPR ?= hlpr -d $(S_DIR)

all: prep-local view

view-local:
	@echo $(S_FILES)
	@echo $(O_DIR)

all-local:
	$(HLPR) xml signatures
	$(HLPR) xml clicks
	$(HLPR) xml descs

install-local:
	cp $(wildcard $(O_DIR)/w*_desc.properties) $(T_DIR)

clean-local:
	-$(RM) $(wildcard $(O_DIR)/*.properties)

view:: view-local
	@echo $(wildcard $(O_DIR)/w*_desc.properties)


