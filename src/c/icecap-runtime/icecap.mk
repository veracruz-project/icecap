$(eval $(call lame-leaf,icecap_runtime))

gen-hdrs-icecap_runtime += icecap_runtime/config_in.h

$(BUILD)/include/icecap_runtime/config_in.h: $(ICECAP_RUNTIME_CONFIG_IN)
	install -D -T $< $@
