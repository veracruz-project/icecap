CC     := $(CROSS_COMPILE)gcc
AR     := $(CROSS_COMPILE)ar
RANLIB := $(CROSS_COMPILE)ranlib

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
build = $(BUILD)/$(trg)

dirs = $(if $(src),$(patsubst $(src)/%, $(build)/%, $(shell find $(src)/ -type d)))

srcs = $(if $(src),$(shell find $(src) -name '*.c' -o -name '*.S' -o -name '*.s'))

objs = \
	$(patsubst $(src)/%.c, $(build)/%.o, \
	$(patsubst $(src)/%.S, $(build)/%.o, \
	$(patsubst $(src)/%.s, $(build)/%.o, \
		$(srcs))))

incs = $(if $(inc),$(shell find $(inc) -name '*.h'))

BUILD ?= build
INSTALL = install

CPPFLAGS += $(foreach x,$(inc),-I $(x)) $(foreach trg,$(libs),$(foreach x,$(inc),-I $(x)))

CFLAGS += -nostdinc -ffreestanding
CFLAGS += -Wa,--noexecstack
CFLAGS += -Wall -Werror
CFLAGS += -ffunction-sections -fdata-sections
CFLAGS += -g -funwind-tables -fno-asynchronous-unwind-tables # -fexceptions?
CFLAGS += -pipe
CFLAGS += -O3

LDFLAGS += -g -ffreestanding -nostdlib -L$(BUILD) #  -Wl,--eh-frame-hdr?

LDLIBS += -lgcc

cc_cmd = $(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<
install_cmd = $(INSTALL) -D -m 644 $< $@

define ar_cmd
	rm -f $@
	$(AR) rc $@ $^
	$(RANLIB) $@
endef

out_libs = $(foreach trg,$(libs),$(if $(src),$(OUT)/lib/lib$(lib).a))
out_hdrs = $(foreach trg,$(libs),$(foreach x,$(inc),$(patsubst $(x)/%.h,$(OUT)/include/%.h,$(incs))))
out_exes = $(foreach exe,$(exes),$(OUT)/bin/$(exe).elf)

.PHONY: all clean install

all: $(foreach trg,$(libs),$(if $(src),$(BUILD)/lib$(lib).a)) $(foreach exe,$(exes),$(BUILD)/$(exe).elf)

clean:
	rm -rf $(BUILD)

install: $(out_libs) $(out_hdrs) $(out_exes)

$(OUT)/lib/lib%.a: $(BUILD)/lib%.a
	$(install_cmd)

$(OUT)/bin/%.elf: $(BUILD)/%.elf
	$(install_cmd)

define rules_for_trg

$(dirs):
	mkdir -p $$@

$(objs): | $(dirs)

$(build)/%.o: $(src)/%.c
	$$(cc_cmd)

$(build)/%.o: $(src)/%.S
	$$(cc_cmd)

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
	$$(CC) $$(LDFLAGS) $$(ldflags-$(exe)) $(objs) $$(ldlibs-$(exe)) $$(LDLIBS) -o $$@

endef

$(eval $(foreach trg,$(libs),$(rules_for_lib)))
$(eval $(foreach trg,$(exes),$(rules_for_exe)))
