BUILD ?= build

CC      := $(CROSS_COMPILE)gcc
AR      := $(CROSS_COMPILE)ar
RANLIB  := $(CROSS_COMPILE)ranlib
INSTALL := install

here = $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

trg = $(1)
lib = $(trg)
exe = $(trg)

define lame-leaf
	libs += $(lib)
	src-$(lib) := $(here)/src
	inc-$(lib) := $(here)/include
endef

define lame-branch
	include $(foreach sub,$(1),$(here)/$(sub)/icecap.mk)
endef

libs :=
exes :=

include $(ROOTS)

src = $(src-$(trg))
inc = $(inc-$(trg))
gen-hdrs = $(gen-hdrs-$(trg))
build = $(BUILD)/$(trg)

dirs = $(if $(src),$(patsubst $(src)/%, $(build)/%, $(shell find $(src)/ -type d)))

srcs = $(if $(src),$(shell find $(src)/ -not -type d -name '*.c' -o -name '*.S' -o -name '*.s'))

objs = \
	$(patsubst $(src)/%.c, $(build)/%.o, \
	$(patsubst $(src)/%.S, $(build)/%.o, \
	$(patsubst $(src)/%.s, $(build)/%.o, \
		$(srcs))))

hdrs = $(if $(inc),$(shell find $(inc)/ -not -type d -name '*.h'))

cppflags = $(CPPFLAGS)
cppflags += \
	$(foreach x,$(inc),-I $(x)) $(foreach trg,$(libs),$(foreach x,$(inc),-I $(x))) \
	-I$(BUILD)/include

cflags = $(CFLAGS)
cflags += -nostdinc -ffreestanding
cflags += -Wa,--noexecstack
cflags += -Wall -Werror
cflags += -ffunction-sections -fdata-sections
cflags += -g -funwind-tables -fno-asynchronous-unwind-tables # -fexceptions?
cflags += -pipe
cflags += -O3

ldflags = $(LDFLAGS)
ldflags += -g -ffreestanding -nostdlib -L$(BUILD) #  -Wl,--eh-frame-hdr?

ldlibs = $(LDLIBS)
ldlibs += -lgcc

cc_cmd = $(CC) $(cflags) $(cflags-$(trg)) $(cppflags) $(cppflags-$(trg)) -c -o $@ $<
ld_cmd = $(CC) $(ldflags) $(ldflags-$(exe)) $(objs) $(ldlibs-$(exe)) $(ldlibs) -o $@
install_cmd = $(INSTALL) -D -m 644 $< $@

define ar_cmd
	rm -f $@
	$(AR) rc $@ $^
	$(RANLIB) $@
endef

out_exes = $(foreach exe,$(exes),$(OUT)/bin/$(exe).elf)
out_libs = $(foreach trg,$(libs),$(if $(src),$(OUT)/lib/lib$(lib).a))
out_hdrs = $(out_gen_hdrs) $(foreach trg,$(libs),$(foreach x,$(inc),$(patsubst $(x)/%.h,$(OUT)/include/%.h,$(hdrs))))
out_gen_hdrs = $(foreach trg,$(libs),$(foreach x,$(gen-hdrs),$(OUT)/include/$(x)))
build_gen_hdrs = $(foreach trg,$(libs),$(foreach x,$(gen-hdrs),$(BUILD)/include/$(x)))

.PHONY: all clean install

all: $(foreach trg,$(libs),$(if $(src),$(BUILD)/lib$(lib).a)) $(foreach exe,$(exes),$(BUILD)/$(exe).elf)

clean:
	rm -rf $(BUILD)

install: $(out_libs) $(out_hdrs) $(out_exes)

$(OUT)/lib/lib%.a: $(BUILD)/lib%.a
	$(install_cmd)

$(OUT)/bin/%.elf: $(BUILD)/%.elf
	$(install_cmd)

$(OUT)/include/%.h: $(BUILD)/include/%.h
	$(install_cmd)

define rules_for_trg

$(extra-rules-$(trg))

$(dirs):
	mkdir -p $$@

$(objs): | $(dirs)

$(objs): $(build_gen_hdrs)

$(build)/%.o: $(src)/%.c
	$$(call cc_cmd,$(trg))

$(build)/%.o: $(src)/%.S
	$$(call cc_cmd,$(trg))

endef

define rules_for_inc

$(OUT)/include/%.h: $(x)/%.h
	$$(install_cmd)

endef

define rules_for_lib

$(rules_for_trg)

$(BUILD)/lib$(lib).a: $(objs)
	$$(ar_cmd)

$(eval $(foreach x,$(inc),$(rules_for_inc)))

endef

define rules_for_exe

$(rules_for_trg)

$(BUILD)/$(exe).elf: $(objs) $(foreach trg,$(deps-$(trg)),$(BUILD)/lib$(lib).a)
	$$(call ld_cmd,$(trg))

endef

$(eval $(foreach trg,$(libs),$(rules_for_lib)))
$(eval $(foreach trg,$(exes),$(rules_for_exe)))
