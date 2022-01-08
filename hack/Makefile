.PHONY: none
none:

### Source code formatting ###

.PHONY: check-formatting
check-formatting: rustfmt-check check-generic-formatting

.PHONY: rustfmt
rustfmt:
	cd ../src/rust && nix-shell --pure --run 'make fmt'

.PHONY: rustfmt-check
rustfmt-check:
	cd ../src/rust && nix-shell --pure --run 'make fmt-check'

check_generic_formatting_ignore_flags = \
	-path ./.git -prune -o \
	-path ./nixpkgs -prune -o \
	-path ./nix/nix-linux -prune -o \
	-path ./docs/images -prune -o \
	-path '*.patch' -o \
	-path ./tmp -prune

.PHONY: check-generic-formatting
check-generic-formatting:
	cd .. && find . ! \( $(check_generic_formatting_ignore_flags) \) -type f | \
		$$(nix-build -A pkgs.dev.python3 --no-out-link)/bin/python3 ./hack/check-generic-formatting.py

### Avoiding cache misses ###

.PHONY: check-source-filters
check-source-filters:
	CURRENT_REV="$$(git show -s --format=%H)" \
		nix-build check-source-filters.nix -A test --no-out-link

ifneq ($(F),1)
deep_clean_dry_run := -n
endif

# NOTE
# Must provide `F=1`, otherwise dry run
.PHONY: deep-clean
deep-clean:
	cd .. && git clean -Xdff $(deep_clean_dry_run) \
		--exclude='!tmp/' \
		--exclude='!tmp/**'

### Remote cache maintenance ###

# NOTE
# Must provide `REMOTE=<remote, e.g. ssh host>`
.PHONY: populate-cache
populate-cache:
	test -n "$(REMOTE)"
	drv=$$(nix-instantiate .. -A meta.everything.cached) && \
		nix-store --realise $$drv && \
		nix-copy-closure --include-outputs --to "$(REMOTE)" $$drv
