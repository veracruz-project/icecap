PLAT ?= virt

out := out

.PHONY: all
all: firmware host-tools build-tools host-kernel realm-kernel html-docs

$(out):
	mkdir -p $@

.PHONY: clean
clean:
	rm -rf $(out)

.PHONY: firmware
firmware: | $(out)
	nix-build -A pkgs.none.icecap.configured.$(PLAT).icecapFirmware.display -o $(out)/$@-$(PLAT)

.PHONY: host-kernel
host-kernel: | $(out)
	nix-build -A meta.display.$@.$(PLAT) -o $(out)/$@-$(PLAT)

.PHONY: realm-kernel
realm-kernel: | $(out)
	nix-build -A meta.display.$@ -o $(out)/$@

.PHONY: host-tools
host-tools: | $(out)
	nix-build -A meta.display.$@ -o $(out)/$@

.PHONY: build-tools
build-tools: | $(out)
	nix-build -A meta.display.$@ -o $(out)/$@

.PHONY: html-docs
html-docs: check-generated-sources | $(out)
	nix-build -A meta.generatedDocs.html -o $(out)/$@


.PHONY: everything
everything: check-generated-sources
	nix-build -A meta.everything.all --no-out-link

.PHONY: everything-pure
everything-pure:
	nix-build -A meta.everything.pure --no-out-link

.PHONY: everything-cached
everything-cached:
	nix-build -A meta.everything.cached --no-out-link

.PHONY: ad-hoc-build-tests
ad-hoc-build-tests: check-generated-sources
	nix-build -A meta.adHocBuildTests.all --no-out-link

.PHONY: tcb-size
tcb-size:
	report=$$(nix-build -A meta.tcbSize --no-out-link) && cat $$report

.PHONY: check-generated-sources
check-generated-sources:
	script=$$(nix-build -A meta.generatedSources.check --no-out-link) && $$script

.PHONY: update-generated-sources
update-generated-sources:
	script=$$(nix-build -A meta.generatedSources.update --no-out-link) && $$script
