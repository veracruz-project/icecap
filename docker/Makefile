icecap_root := ../

label := icecap
image_repository := icecap
image_tag := $(image_repository):stateless
container_name := icecap-stateless
nix_root_volume_name := icecap-nix-root
dockerfile := Dockerfile

uid := $(shell id -u)
gid := $(shell id -g)


.PHONY: none
none:

.PHONY: build
build:
	docker build \
		--build-arg UID=$(uid) --build-arg GID=$(gid) \
		--label $(label) -t $(image_tag) -f $(dockerfile) .

.PHONY: initialize-volume
initialize-volume: build
	if [ -z "$$(docker volume ls -q -f "name=^$(nix_root_volume_name)$$")" ]; then \
		docker volume create --label $(label) $(nix_root_volume_name) && \
		docker run --privileged --rm --label $(label) -w /home/x \
			--mount type=volume,src=$(nix_root_volume_name),dst=/nix \
			$(image_tag) flock /nix/.installed.lock bash /setup.sh; \
	fi

.PHONY: run
run: build initialize-volume
	docker run --privileged -d --name $(container_name) --label $(label) \
		--mount type=volume,src=$(nix_root_volume_name),dst=/nix \
		--mount type=bind,src=$(abspath $(icecap_root)),dst=/icecap \
		$(image_tag) sleep inf

.PHONY: exec
exec:
	docker exec -it $(container_name) bash

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
