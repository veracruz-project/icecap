# Exposes a few Nix derivations, mostly for the sake of documentation.

PLAT ?= virt

out := out

.PHONY: all
all:

.PHONY: clean
clean:
	rm -rf $(out)

$(out):
	mkdir -p $@

.PHONY: firmware
firmware: | $(out)
	./build-tool.sh --plat=$(PLAT) target $@ -o $(out)/icecap.img

.PHONY: shadow-vmm
shadow-vmm: | $(out)
	./build-tool.sh --plat=$(PLAT) target $@ -o $(out)/icecap.img

.PHONY: demo
demo: | $(out)
	./build-tool.sh --plat=$(PLAT) target $@ -o $(out)/demo

.PHONY: everything
everything: | $(out)
	./build-tool.sh --plat=$(PLAT) target $@ -o $(out)/roots
