# weaves

## Post-process the snapshot pages and categorize

# The EditText and RadioButton items have text and are distinctive for each page

# Extract these and put them into a file for each page captured.
# Generate checksums for each page and group by those.
# Post-process those files to produce a .properties file that describes that page.

# I also generate an xpath file. I don't need to use that.

.PHONY: all-local prep-local view-local

O_DIR?=cache

HLPR ?= hlpr 

S_DIR ?= pages
S_FILES ?= $(wildcard $(S_DIR)/w*)

T_FILES2 := $(addprefix $(O_DIR)/,$(addsuffix -text.xml,$(notdir $(S_FILES))))
T_FILES3 := $(addprefix $(O_DIR)/,$(addsuffix -xpath.xml,$(notdir $(S_FILES))))

T_FILES := $(T_FILES2) $(T_FILES3)

all: prep-local view

view-local:
	@echo $(S_FILES)
	@echo $(O_DIR)
	@echo $(addprefix $(O_DIR)/,$(addsuffix -radio.xml,$(notdir $(S_FILES))))
	@echo $(addprefix $(O_DIR)/,$(addsuffix -text.xml,$(notdir $(S_FILES))))
	@echo $(addprefix $(O_DIR)/,$(addsuffix -xpath.xml,$(notdir $(S_FILES))))

prep-local:
	test -d $(O_DIR) || mkdir -p $(O_DIR)

all-local: $(T_FILES)

all-local-2: $(T_FILES2)

$(O_DIR)/%-text.xml: $(S_DIR)/%
	xsltproc -o $@ text.xslt ${X_OPTS} $<

$(O_DIR)/%-xpath.xml: xpath.xslt $(S_DIR)/%
	xsltproc -o $@ ${X_OPTS} $+ 

all-local2: text.sums

%.list:
	ls -d $(O_DIR)/*-$(basename $@).* > $@

%.sums: %.list 
	sum $(shell cat $< | xargs) | sort -nk1 | $(HLPR) list first > $@

ifdef S_FILE

S0_FILES = $(shell cat $(S_FILE) | cut -d' ' -f2 | xargs)
R1_FILES = $(S0_FILES:.xml=.properties)

$(O_DIR)/%.properties: $(O_DIR)/%.xml
	$(HLPR) list props-inc $+ > $@

all-local-3: $(R1_FILES)

view-local-3::
	@echo $(S0_FILES)
	@echo $(R1_FILES)

endif

clean-local:
	-$(RM) $(wildcard $(O_DIR)/*.xml)

view:: view-local

