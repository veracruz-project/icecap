icecap_root := ../
nix_root := ./nix-root

label := icecap
image_tag := icecap
container_name := icecap

uid := $(shell id -u)
gid := $(shell id -g)

.PHONY:
all: run

.PHONY:
build:
	docker build --build-arg UID=$(uid) --build-arg GID=$(gid) --label $(label) -t $(image_tag) .

$(nix_root):
	mkdir -p -m 0755 $@

$(nix_root)/.installed: build $(nix_root)
	docker run --privileged --rm --label $(label) -w /home/x \
		--mount type=bind,src=$(abspath $(nix_root)),dst=/nix \
		$(image_tag) flock /nix/.installed.lock bash /setup.sh

.PHONY:
run: build $(nix_root)/.installed
	docker run --privileged -d --name $(container_name) --label $(label) \
		--mount type=bind,src=$(abspath $(nix_root)),dst=/nix \
		--mount type=bind,src=$(abspath $(icecap_root)),dst=/icecap \
		$(image_tag) sleep inf

.PHONY:
exec:
	docker exec -it $(container_name) bash

.PHONY:
logs:
	for id in $$(docker ps -aq -f "label=$(label)"); do \
		docker logs $$id; \
	done

.PHONY:
clean:
	for id in $$(docker ps -aq -f "label=$(label)"); do \
		docker rm -f $$id; \
	done

.PHONY:
deep-clean: clean
	if [ -d $(nix_root) ]; then \
		chmod -R u+w $(nix_root); \
		rm -rf $(nix_root); \
	fi


stateful_image_tag := $(image_tag)_stateful
stateful_container_name := $(container_name)_stateful
stateful_dockerfile := Dockerfile.stateful

.PHONY:
build-stateful:
	docker build --build-arg UID=$(uid) --build-arg GID=$(gid) --label $(label) -t $(stateful_image_tag) -f $(stateful_dockerfile) .

.PHONY:
run-stateful: build-stateful
	docker run --privileged -d --name $(stateful_container_name) --label $(label) \
		--mount type=bind,src=$(abspath $(icecap_root)),dst=/icecap \
		$(stateful_image_tag) sleep inf

.PHONY:
exec-stateful:
	docker exec -it $(stateful_container_name) bash
