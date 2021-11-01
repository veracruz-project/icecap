libs += capdl-loader-core
src-capdl-loader-core := $(CAPDL_LOADER_EXTERNAL_SOURCE)/src
inc-capdl-loader-core := $(here)/include $(CAPDL_LOADER_EXTERNAL_SOURCE)/include
gen-hdrs-capdl-loader-core += \
	capdl_loader_app/platform_info.h \
	capdl_loader_app/config_in.h

$(BUILD)/include/capdl_loader_app/platform_info.h: $(CAPDL_LOADER_PLATFORM_INFO_H)
	install -D -T $< $@

$(BUILD)/include/capdl_loader_app/config_in.h: $(CAPDL_LOADER_CONFIG_IN_H)
	install -D -T $< $@

# HACK
CFLAGS += -Wno-unused-variable
CFLAGS += -Wno-unused-function
CFLAGS += -Wno-unused-but-set-variable
