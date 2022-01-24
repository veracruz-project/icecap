exes += capdl-loader
src-capdl-loader = $(CAPDL_LOADER_SPEC_SRC)
ldlibs-capdl-loader := \
	-Wl,--start-group \
	-licecap-runtime -licecap-utils -licecap-some-libc -lcpio -lcapdl-loader-shim -lcapdl-loader-core \
	$(CAPDL_LOADER_CPIO_O) \
	-Wl,--end-group
