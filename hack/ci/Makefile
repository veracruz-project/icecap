icecap_dir = ../..
hack_dir = ..

.PHONY: check
check:
	$(MAKE) -C $(icecap_dir) everything
	$(MAKE) -C $(icecap_dir) run-automated-tests
	$(MAKE) -C $(hack_dir) check-formatting
