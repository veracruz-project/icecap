.PHONY: none
none:

# NOTE
# `git clean -xdn` is useful for debugging failures.
.PHONY: source-test
source-test:
	CURRENT_REV="$$(git show -s --format=%H)" \
		nix-build source-test.nix -A test

# NOTE
# Must provide `REMOTE=<remote, e.g. ssh host>`.
.PHONY: populate-cache
populate-cache:
	test -n "$(REMOTE)"
	drv=$$(nix-instantiate populate.nix) && \
		nix-store --realise $$drv && \
		nix-copy-closure --include-outputs --to "$(REMOTE)" $$drv
