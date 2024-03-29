.PHONY: all
all: build doc

.PHONY: clean
clean:
	rm -rf target

define cargo_fmt
	cargo fmt --all -- $(1)
	cargo fmt -- $(1) $$(find ../../examples -type f -name '*.rs')
endef

.PHONY: fmt
fmt:
	$(call cargo_fmt,)

.PHONY: fmt-check
fmt-check:
	$(call cargo_fmt,--check -l)

.PHONY: build
build: build-seL4 build-linux

.PHONY: doc
doc: doc-seL4 doc-linux

icecap_plat := $(ICECAP_PLAT)

icecap_rust_flags := \
	--cfg=icecap_plat=\"$(icecap_plat)\" \
	-L$(LIBSEL4)/lib -L$(ICECAP_RUNTIME)/lib

icecap_env := \
	RUST_TARGET_PATH=$(abspath support/targets) \
	CARGO_TARGET_AARCH64_ICECAP_RUSTFLAGS="$(icecap_rust_flags)" \
	CARGO_TARGET_AARCH64_ICECAP_RUSTDOCFLAGS="$(icecap_rust_flags) --enable-index-page" \
	BINDGEN_EXTRA_CLANG_ARGS="-I$(LIBSEL4)/include"

icecap_build_std_args := \
	-Z build-std=core,alloc,compiler_builtins -Z build-std-features=compiler-builtins-mem

ifdef P
package_args_for := -p $(P)
else
package_args_for = $(shell awk '{print "-p " $$$$0}' < support/crates-for-$(1).txt)
endif

seL4_package_args = $(call package_args_for,seL4)
linux_package_args = $(call package_args_for,linux)

.PHONY: build-seL4
build-seL4:
	$(icecap_env) \
		cargo build --locked \
			--target aarch64-icecap \
			$(icecap_build_std_args) \
			$(seL4_package_args)

.PHONY: build-linux
build-linux:
	cargo build --locked \
		$(linux_package_args)

.PHONY: doc-seL4
doc-seL4:
	$(icecap_env) \
		cargo doc --locked \
			--target aarch64-icecap \
			$(icecap_build_std_args) \
			$(seL4_package_args)

.PHONY: doc-linux
doc-linux:
	RUSTDOCFLAGS="-Z unstable-options --enable-index-page" \
		cargo doc --locked \
			$(linux_package_args)
