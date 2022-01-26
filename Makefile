PLAT ?= virt

out := out

.PHONY: all
all: hypervisor-firmware html-docs

$(out):
	mkdir -p $@

.PHONY: clean
clean:
	rm -rf $(out)

.PHONY: hypervisor-firmware
hypervisor-firmware: | $(out)
	nix-build -A hypervisor.framework.pkgs.none.icecap.configured.$(PLAT).icecapFirmware.display -o $(out)/$@-$(PLAT)

.PHONY: html-docs
html-docs: check-generated-sources | $(out)
	nix-build -A framework.generatedDocs.html -o $(out)/$@

.PHONY: show-tcb-size
show-hypervisor-tcb-size:
	report=$$(nix-build -A hypervisor.tcbSize --no-out-link) && cat $$report

.PHONY: everything
everything: check-generated-sources
	nix-build -A everything.all --no-out-link

.PHONY: everything-pure
everything-pure:
	nix-build -A everything.pure --no-out-link

.PHONY: everything-cached
everything-cached:
	nix-build -A everything.cached --no-out-link

.PHONY: everything-with-excess
everything-with-excess: everything
	nix-build -A testStandAlone

.PHONY: check-generated-sources
check-generated-sources:
	script=$$(nix-build -A framework.generatedSources.check --no-out-link) && $$script

.PHONY: update-generated-sources
update-generated-sources:
	script=$$(nix-build -A framework.generatedSources.update --no-out-link) && $$script

.PHONY: run-automated-tests
run-automated-tests:
	script=$$(nix-build -A framework.automatedTests.runAll --no-out-link) && $$script
	script=$$(nix-build -A hypervisor.automatedTests.runAll --no-out-link) && $$script
