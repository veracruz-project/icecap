out := out

.PHONY: none
none:

.PHONY: update-generated-sources
update-generated-sources:
	script=$$(nix-build -A meta.generatedSources.update --no-out-link) && $$script

.PHONY: check-generated-sources
check-generated-sources:
	script=$$(nix-build -A meta.generatedSources.check --no-out-link) && $$script

.PHONY: html-docs
html-docs: check-generated-sources | $(out)
	nix-build -A meta.generatedDocs.html -o $(out)/html-docs

.PHONY: tcb-size
tcb-size:
	report=$$(nix-build -A meta.tcbSize --no-out-link) && cat $$report

.PHONY: everything
everything: check-generated-sources
	nix-build -A meta.everything.all --no-out-link

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

.PHONY: deep-clean
deep-clean: clean
	git clean -Xdff \
		--exclude='!docker/nix-root/' \
		--exclude='!docker/nix-root/**' \
		--exclude='!tmp/' \
		--exclude='!tmp/**'
