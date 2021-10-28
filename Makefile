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
