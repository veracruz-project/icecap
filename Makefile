out := out

.PHONY: none
none:

.PHONY: update-generated-sources
update-generated-sources:
	script=$$(nix-build -A meta.generatedSources.update --no-out-link) && $$script

.PHONY: check-generated-sources
check-generated-sources:
	script=$$(nix-build -A meta.generatedSources.check --no-out-link) && $$script

.PHONY: rustfmt
rustfmt:
	nix-shell src/rust/shell.nix --pure --run 'make -C src/rust fmt'

.PHONY: rustfmt-check
rustfmt-check:
	nix-shell src/rust/shell.nix --pure --run 'make -C src/rust fmt-check'

.PHONY: html-docs
html-docs: check-generated-sources | $(out)
	nix-build -A meta.generatedDocs.html -o $(out)/html-docs

.PHONY: tcb-size
tcb-size:
	report=$$(nix-build -A meta.tcbSize --no-out-link) && cat $$report

.PHONY: everything
everything: check-generated-sources
	nix-build -A meta.everything.all --no-out-link

.PHONY: everything-cached
everything-cached:
	nix-build -A meta.everything.cached --no-out-link

.PHONY: everything-pure
everything-pure:
	nix-build -A meta.everything.pure --no-out-link

.PHONY: ad-hoc-build-tests
ad-hoc-build-tests: check-generated-sources
	nix-build -A meta.adHocBuildTests.all --no-out-link

$(out):
	mkdir -p $@

.PHONY: clean
clean:
	rm -rf $(out)

ifneq ($(F),1)
deep_clean_dry_run := -n
endif

.PHONY: deep-clean
deep-clean:
	git clean -Xdff $(deep_clean_dry_run) \
		--exclude='!tmp/' \
		--exclude='!tmp/**'

check_formatting_ignore_flags = \
	-path ./.git -prune -o \
	-path ./nixpkgs -prune -o \
	-path ./nix/nix-linux -prune -o \
	-path ./docs/images -prune -o \
	-path '*.patch' -o \
	-path ./tmp -prune 

check_formatting_find_invocation = find . ! \( $(check_formatting_ignore_flags) \) -type f

.PHONY: check-formatting
check-formatting:
	for f in $$($(check_formatting_find_invocation)); do \
		./hack/check-formatting.py $$f; \
	done
