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
	./build.py --plat=$(PLAT) target $@ -o $(out)/icecap.img

.PHONY: shadow-vmm
shadow-vmm: | $(out)
	./build.py --plat=$(PLAT) target $@ -o $(out)/icecap.img

.PHONY: demo
demo: | $(out)
	./build.py --plat=$(PLAT) target $@ -o $(out)/demo

.PHONY: everything
everything: | $(out)
	./build.py --plat=$(PLAT) target $@ -o $(out)/roots

###

.PHONY: update-generated-sources
update-generated-sources:
	script=$$(nix-build -A meta.generate.update --no-out-link) && $$script

.PHONY: check-generated-sources
check-generated-sources:
	script=$$(nix-build -A meta.generate.check --no-out-link) && $$script

.PHONY: build-test
build-test:
	nix-build -A meta.buildTest --no-out-link

.PHONY: ad-hoc-build-tests
ad-hoc-build-tests:
	nix-build -A meta.adHocBuildTests.all --no-out-link
