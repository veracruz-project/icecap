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
	nix-build -A pkgs.none.icecap.configured.$(PLAT).icecapFirmware.image -o $(out)/icecap.img

.PHONY: shadow-vmm
shadow-vmm: | $(out)
	nix-build -A pkgs.musl.icecap.icecap-host -o $(out)/shadow-vmm

.PHONY: demo
demo: | $(out)
	nix-build -A meta.demos.realm-vm.$(PLAT).run -o $(out)/demo

.PHONY: everything
everything:
	nix-build -A meta.buildTest --no-out-link

.PHONY: ad-hoc-build-tests
ad-hoc-build-tests:
	nix-build -A meta.adHocBuildTests.all --no-out-link

###

.PHONY: update-generated-sources
update-generated-sources:
	script=$$(nix-build -A meta.generate.update --no-out-link) && $$script

.PHONY: check-generated-sources
check-generated-sources:
	script=$$(nix-build -A meta.generate.check --no-out-link) && $$script
