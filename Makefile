out := out

.PHONY: none
none:

$(out):
	mkdir -p $@

.PHONY: clean
clean:
	rm -rf $(out)

.PHONY: check
check: check-generated-sources rustfmt-check check-formatting everything


### Pure Nix ###

.PHONY: everything
everything: check-generated-sources
	nix-build -A meta.everything.all --no-out-link

.PHONY: everything-pure
everything-pure:
	nix-build -A meta.everything.pure --no-out-link

.PHONY: everything-cached
everything-cached:
	nix-build -A meta.everything.cached --no-out-link

.PHONY: ad-hoc-build-tests
ad-hoc-build-tests: check-generated-sources
	nix-build -A meta.adHocBuildTests.all --no-out-link

.PHONY: tcb-size
tcb-size:
	report=$$(nix-build -A meta.tcbSize --no-out-link) && cat $$report

.PHONY: html-docs
html-docs: check-generated-sources | $(out)
	nix-build -A meta.generatedDocs.html -o $(out)/html-docs


### Source code maintenance ###

.PHONY: check-generated-sources
check-generated-sources:
	script=$$(nix-build -A meta.generatedSources.check --no-out-link) && $$script

.PHONY: update-generated-sources
update-generated-sources:
	script=$$(nix-build -A meta.generatedSources.update --no-out-link) && $$script

.PHONY: rustfmt
rustfmt:
	nix-shell src/rust/shell.nix --pure --run 'make -C src/rust fmt'

.PHONY: rustfmt-check
rustfmt-check:
	nix-shell src/rust/shell.nix --pure --run 'make -C src/rust fmt-check'

check_formatting_ignore_flags = \
	-path ./.git -prune -o \
	-path ./nixpkgs -prune -o \
	-path ./nix/nix-linux -prune -o \
	-path ./docs/images -prune -o \
	-path '*.patch' -o \
	-path '*.swp' -o \
	-path ./tmp -prune 

.PHONY: check-formatting
check-formatting:
	find . ! \( $(check_formatting_ignore_flags) \) -type f | \
		$$(nix-build -A pkgs.dev.python3 --no-out-link)/bin/python3 ./hack/check-formatting.py

ifneq ($(F),1)
deep_clean_dry_run := -n
endif

# NOTE
# Must provide `F=1`, otherwise dry run
.PHONY: deep-clean
deep-clean:
	git clean -Xdff $(deep_clean_dry_run) \
		--exclude='!tmp/' \
		--exclude='!tmp/**'

.PHONY: check-source-filters
check-source-filters:
	CURRENT_REV="$$(git show -s --format=%H)" \
		nix-build hack/check-source-filters.nix -A test --no-out-link


### Remote cache maintenance ###

# NOTE
# Must provide `REMOTE=<remote, e.g. ssh host>`
.PHONY: populate-cache
populate-cache:
	test -n "$(REMOTE)"
	drv=$$(nix-instantiate -A meta.everything.cached) && \
		nix-store --realise $$drv && \
		nix-copy-closure --include-outputs --to "$(REMOTE)" $$drv
