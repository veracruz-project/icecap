.PHONY: all
all: doc build

.PHONY: doc
doc: doc-seL4 doc-linux

.PHONY: build
build: build-seL4 build-linux

.PHONY: doc-seL4
doc-seL4:
	RUST_TARGET_PATH=$(abspath support/targets) \
	CARGO_TARGET_AARCH64_ICECAP_RUSTDOCFLAGS="--cfg=icecap_plat=\"virt\"" \
		cargo doc \
			-Z unstable-options \
			--locked \
			--target aarch64-icecap \
			-Z avoid-dev-deps \
			-Z build-std=core,alloc,compiler_builtins -Z build-std-features=compiler-builtins-mem \
			-p $(shell awk '{print "-p" $$$$0}' < support/crates-for-seL4.txt)

.PHONY: doc-linux
doc-linux:
	cargo doc \
		-Z unstable-options \
		--locked \
		-Z avoid-dev-deps \
		-p $(shell awk '{print "-p" $$$$0}' < support/crates-for-linux.txt)

.PHONY: build-seL4
build-seL4:
	RUST_TARGET_PATH=$(abspath support/targets) \
	CARGO_TARGET_AARCH64_ICECAP_RUSTFLAGS="--cfg=icecap_plat=\"virt\" -L$(LIBSEL4)/lib -L$(ICECAP_RUNTIME)/lib" \
		cargo build \
			-Z unstable-options \
			--locked \
			--target aarch64-icecap \
			-Z avoid-dev-deps \
			-Z build-std=core,alloc,compiler_builtins -Z build-std-features=compiler-builtins-mem \
			-p $(shell awk '{print "-p" $$$$0}' < support/crates-for-seL4.txt)

.PHONY: build-linux
build-linux:
	cargo build \
		-Z unstable-options \
		--locked \
		-Z avoid-dev-deps \
		-p $(shell awk '{print "-p" $$$$0}' < support/crates-for-linux.txt)

.PHONY: clean
clean:
	rm -rf target
