PLAT ?= virt

out := out

.PHONY: none
none:

.PHONY: clean
clean:
	rm -rf $(out)

$(out):
	mkdir -p $@

.PHONY: hypervisor-demo
hypervisor-demo: | $(out)
	nix-build -A hypervisor-demo.$(PLAT).run -o $(out)/hypervisor-demo
