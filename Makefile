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
firmware: $(out)
	nix-build -A pkgs.none.icecap.configured.$(PLAT).icecapFirmware.image -o $(out)/icecap.img

.PHONY: demo
demo: $(out)
	nix-build -A meta.demos.realm-vm.$(PLAT).run -o $(out)/demo

.PHONY: everything
everything: $(out)
	nix-build -A meta.buildTest -o $(out)/roots
