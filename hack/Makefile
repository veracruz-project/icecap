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

check_generic_formatting_ignore_patterns = \
	-e '^docs/images' \
	-e '.patch$$'

.PHONY: check-generic-formatting
check-generic-formatting:
	cd .. && git ls-files | \
		grep -v $(check_generic_formatting_ignore_patterns) | \
		( \
			while read path; do \
				[ -f "$$path" ] && echo $$path; \
			done \
		) | \
		$$(nix-build -A framework.pkgs.dev.python3 --no-out-link)/bin/python3 ./hack/check-generic-formatting.py

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
# - required: `REMOTE=<remote, e.g. ssh host>`
# - optional: `ROOT=<attribute path>`

ROOT ?= everything.cached

.PHONY: populate-cache
populate-cache:
	test -n "$(REMOTE)"
	drv=$$(nix-instantiate .. -A $(ROOT)) && \
		nix-store --realise $$drv && \
		closure="$$(nix-store --query --requisites --include-outputs $$drv)" && \
		nix-copy-closure --use-substitutes --include-outputs --to "$(REMOTE)" $$closure
		# NOTE
		# 	Should just be the following, but nix-copy-closure
		# 	--include-outputs doesn't work as expected.
		# nix-copy-closure --use-substitutes --include-outputs --to "$(REMOTE)" $$drv
