.PHONY: all
all: doc build

.PHONY: clean
clean:
	rm -rf target

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

# HACK
.PHONY: sysroot
sysroot:
	RUST_TARGET_PATH=$(abspath support/targets) \
	CARGO_PROFILE_RELEASE_DEBUG=0 \
	CARGO_PROFILE_RELEASE_DEBUG_ASSERTIONS=true \
	RUSTC_BOOTSTRAP=1 \
	CARGO_TARGET_AARCH64_ICECAP_RUSTFLAGS=" \
		-Cforce-unwind-tables=yes -Cembed-bitcode=yes \
		-Z force-unstable-if-unmarked --sysroot /dev/null \
		--cfg=icecap_plat=\"virt\" -L$(LIBSEL4)/lib -L$(ICECAP_RUNTIME)/lib" \
	__CARGO_DEFAULT_LIB_METADATA="icecap-sysroot" \
	cargo build \
		-Z unstable-options \
		--locked \
		-Z avoid-dev-deps \
		--target aarch64-icecap \
		-Zbinary-dep-depinfo \
		--release \
		--target-dir target/sysroot \
		--features compiler-builtins-mem \
		--manifest-path ../../../local/rust/library/test/Cargo.toml
