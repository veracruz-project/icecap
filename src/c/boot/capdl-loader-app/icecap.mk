exes += capdl-loader
src-capdl-loader = $(CAPDL_LOADER_SPEC_SRC)
ldlibs-capdl-loader := \
	-Wl,--start-group \
	-licecap_runtime -licecap_utils -licecap_pure -lcpio -lcapdl_support_hack -lcapdl_loader_core \
	$(CAPDL_LOADER_CPIO_O) \
	-Wl,--end-group
