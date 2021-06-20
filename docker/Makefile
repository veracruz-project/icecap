nix_root := ./nix-root
icecap_root := ../

image_tag := icecap
container_name := icecap
setup_container_name := $(container_name)_setup
label := icecap

uid := $(shell id -u)
gid := $(shell id -g)

.PHONY:
all: run

.PHONY:
build:
	docker build --build-arg UID=$(uid) --build-arg GID=$(gid) --label $(label) -t $(image_tag) .

$(nix_root):
	mkdir -p $@

$(nix_root)/.installed: build $(nix_root)
	docker run --privileged --rm  --label $(label) \
		--mount type=bind,src=$(abspath $(nix_root)),dst=/nix \
		$(image_tag) flock /nix/.installed.lock bash setup.sh

.PHONY:
run: build $(nix_root)/.installed
	docker run -d --privileged --name $(container_name) --label $(label) \
		--mount type=bind,src=$(abspath $(nix_root)),dst=/nix \
		--mount type=bind,src=$(abspath $(icecap_root)),dst=/icecap \
		$(image_tag) sleep inf

.PHONY:
exec:
	docker exec -it -w /icecap $(container_name) /bin/bash

.PHONY:
logs:
	for id in $$(docker ps -aq -f "label=$(label)"); do \
		docker logs $$id; \
	done

.PHONY:
clean:
	for id in $$(docker ps -aq -f "label=$(label)"); do \
		docker kill $$id || true; \
		docker rm $$id || true; \
	done

.PHONY:
deep-clean: clean
	rm -rf $(nix_root)
