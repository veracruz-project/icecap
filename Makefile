PLAT ?= virt

out := out
tmp := tmp

nix_build := nix-build -j$$(nproc)

.PHONY: all
all:

.PHONY: clean
clean:
	rm -rf $(out)

.PHONY: deep-clean
deep-clean: clean
	git clean -xdf --exclude=$(tmp) --exclude=docker/nix-root

$(out):
	mkdir -p $@

.PHONY: firmware
firmware: $(out)
	$(nix_build) -A pkgs.none.icecap.configured.$(PLAT).icecapFirmware.image -o $(out)/icecap.img

.PHONY: demo
demo: $(out)
	$(nix_build) -A meta.demos.realm-vm.$(PLAT).run -o $(out)/demo

.PHONY: everything
everything: $(out)
	$(nix_build) -A meta.buildTest -o $(out)/roots
