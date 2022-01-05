PLAT ?= virt

out := out

.PHONY: all
all: build

.PHONY: clean
clean:
	rm -rf $(out)

$(out):
	mkdir -p $@

.PHONY: build
build: | $(out)
	nix-build -A $(PLAT).run -o $(out)/demo

.PHONY: run
run: build | $(out)
	$(out)/demo/run
