.PHONY: none
none:

.PHONY: update-generated-sources
update-generated-sources:
	script=$$(nix-build -A meta.generatedSources.update --no-out-link) && $$script

.PHONY: check-generated-sources
check-generated-sources:
	script=$$(nix-build -A meta.generatedSources.check --no-out-link) && $$script

.PHONY: build-tests
build-tests:
	nix-build -A meta.buildTests.all --no-out-link

.PHONY: ad-hoc-build-tests
ad-hoc-build-tests:
	nix-build -A meta.adHocBuildTests.all --no-out-link

.PHONY: html-docs
html-docs:
	nix-build -A meta.generatedDocs.html --no-out-link
