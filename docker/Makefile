nix_root := ./nix-root
icecap_root := ../

image_tag := icecap
container_name := icecap

uid := $(shell id -u)
gid := $(shell id -g)

.PHONY:
all: run

$(nix_root):
	mkdir -p $@

.PHONY:
build:
	docker build --build-arg UID=$(uid) --build-arg GID=$(gid) -t $(image_tag) .

.PHONY:
run: build $(nix_root)
	docker run -d --privileged --name $(container_name) \
		--mount type=bind,src=$(abspath $(nix_root)),dst=/nix \
		--mount type=bind,src=$(abspath $(icecap_root)),dst=/icecap \
		$(image_tag)

.PHONY:
exec:
	docker exec -it -w /icecap $(container_name) /bin/bash

.PHONY:
logs:
	for id in $$(docker ps -aqf "name=$(container_name)"); do \
		docker logs $$id; \
	done

.PHONY:
clean:
	for id in $$(docker ps -aqf "name=$(container_name)"); do \
		docker kill $$id || true; \
		docker rm $$id || true; \
	done
