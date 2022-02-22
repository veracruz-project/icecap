manifest_path = $(abspath $(PROJECT)/Cargo.toml)

cdl_script_path = $(abspath $(PROJECT)/cdl/composition.py)

icedl_components := \
	application \
	serial-server \
	timer-server
