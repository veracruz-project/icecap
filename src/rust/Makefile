.PHONY: all
all: doc build

.PHONY: clean
clean:
	rm -rf target

.PHONY: doc
doc: doc-seL4 doc-linux

.PHONY: build
build: build-seL4 build-linux

package_args_for = $(shell awk '{print "-p " $$$$0}' < support/crates-for-$(1).txt)
seL4_package_args = $(call package_args_for,seL4)
linux_package_args = $(call package_args_for,linux)

icecap_cfg_flags := --cfg=icecap_plat=\"virt\"
icecap_lib_path_flags := -L$(LIBSEL4)/lib -L$(ICECAP_RUNTIME)/lib

icecap_build_std_args := \
	-Z build-std=core,alloc,compiler_builtins -Z build-std-features=compiler-builtins-mem

.PHONY: doc-seL4
doc-seL4:
	RUST_TARGET_PATH=$(abspath support/targets) \
	CARGO_TARGET_AARCH64_ICECAP_RUSTDOCFLAGS="$(icecap_cfg_flags)" \
		cargo doc --locked \
			--target aarch64-icecap \
			$(icecap_build_std_args) \
			$(seL4_package_args)

.PHONY: doc-linux
doc-linux:
	cargo doc --locked \
		$(linux_package_args)

.PHONY: build-seL4
build-seL4:
	RUST_TARGET_PATH=$(abspath support/targets) \
	CARGO_TARGET_AARCH64_ICECAP_RUSTFLAGS="$(icecap_cfg_flags) $(icecap_lib_path_flags)" \
		cargo build --locked \
			--target aarch64-icecap \
			$(icecap_build_std_args) \
			$(seL4_package_args)

.PHONY: build-linux
build-linux:
	cargo build --locked \
		$(linux_package_args)
