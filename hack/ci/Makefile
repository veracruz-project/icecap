top_level_dir = ../..
hack_dir = ..
pages_dir := $(top_level_dir)/public

html_docs_attr_path := framework.generatedDocs.external.html

.PHONY: check
check:
	$(MAKE) -C $(top_level_dir) everything
	$(MAKE) -C $(top_level_dir) run-automated-tests
	$(MAKE) -C $(hack_dir) check-formatting

.PHONY: pages
pages: $(pages_dir)

.PHONY: clean
clean:
	rm -r $(pages_dir)

$(pages_dir):
	result=$$(nix-build $(top_level_dir) -A $(html_docs_attr_path) --no-out-link) && cp -rL --no-preserve=owner,mode $$result $@
