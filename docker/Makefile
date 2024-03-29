STATEFUL ?= $(if $(findstring Linux,$(shell uname -s)),0,1)

icecap_root := ../

label := icecap
image_repository := icecap
image_tag := $(image_repository)
container_name := icecap
nix_root_volume_name := icecap-nix-root
dockerfile := Dockerfile

uid := $(shell id -u)
gid := $(shell id -g)

ifneq ($(STATEFUL),1)
	statefulness_run_prerequisites := initialize-volume
	statefulness_docker_run_args := --mount type=volume,src=$(nix_root_volume_name),dst=/nix
endif

.PHONY: none
none:

.PHONY: build
build:
	docker build \
		--build-arg UID=$(uid) --build-arg GID=$(gid) --build-arg STATEFUL=$(STATEFUL) \
		--label $(label) -t $(image_tag) -f $(dockerfile) .

.PHONY: initialize-volume
initialize-volume: build
	if [ -z "$$(docker volume ls -q -f "name=^$(nix_root_volume_name)$$")" ]; then \
		docker volume create --label $(label) $(nix_root_volume_name) && \
		docker run --privileged --rm --label $(label) -w /home/x \
			$(statefulness_docker_run_args) \
			$(image_tag) flock /nix/.installed.lock bash /setup.sh; \
	fi

.PHONY: run
run: build $(statefulness_run_prerequisites)
	docker run --privileged -d --name $(container_name) --label $(label) \
		$(statefulness_docker_run_args) \
		--mount type=bind,src=$(abspath $(icecap_root)),dst=/icecap \
		$(image_tag) sleep inf

.PHONY: exec
exec:
	docker exec -it $(container_name) bash

.PHONY: show-nix-root
show-nix-root:
	docker inspect icecap-nix-root --format='{{.Mountpoint}}'

.PHONY: rm-container
rm-container:
	for id in $$(docker ps -aq -f "name=^$(container_name)$$"); do \
		docker rm -f $$id; \
	done

.PHONY: rm-volume
rm-volume:
	for volume in $$(docker volume ls -q -f "name=^$(nix_root_volume_name)$$"); do \
		docker volume rm $$volume; \
	done
