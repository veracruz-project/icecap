PLAT ?= virt

out := out

.PHONY: all
all:

.PHONY: clean
clean:
	rm -rf $(out)

$(out):
	mkdir -p $@

.PHONY: hypervisor-demo
hypervisor-demo: | $(out)
	nix-build -A hypervisor.$(PLAT).run -o $(out)/hypervisor-demo
