$(eval $(call lame-leaf,icecap-runtime))

gen-hdrs-icecap-runtime += icecap-runtime/config_in.h

$(BUILD)/include/icecap-runtime/config_in.h: $(ICECAP_RUNTIME_CONFIG_IN)
	install -D -T $< $@
