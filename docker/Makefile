icecap_root := ../
nix_root := ./nix-root

label := icecap

image_tag_base := icecap
image_tag_stateless := $(image_tag_base)_stateless
image_tag_stateful := $(image_tag_base)_stateful

container_name_base := icecap
container_name_stateless := $(container_name_base)_stateless
container_name_stateful := $(container_name_base)_stateful

dockerfile_base := Dockerfile
dockerfile_stateless := $(dockerfile_base).stateless
dockerfile_stateful := $(dockerfile_base).stateful

default_statefulness := stateful

uid := $(shell id -u)
gid := $(shell id -g)


.PHONY: all build run exec

all:

build: build-$(default_statefulness)

run: run-$(default_statefulness)

exec: exec-$(default_statefulness)


### stateful ###

.PHONY: build-stateful
build-stateful:
	docker build \
		--build-arg UID=$(uid) --build-arg GID=$(gid) \
		--label $(label) -t $(image_tag_stateful) -f $(dockerfile_stateful) .

.PHONY: run-stateful
run-stateful: build-stateful
	docker run --privileged -d --name $(container_name_stateful) --label $(label) \
		--mount type=bind,src=$(abspath $(icecap_root)),dst=/icecap \
		$(image_tag_stateful) sleep inf

.PHONY: exec-stateful
exec-stateful:
	docker exec -it $(container_name_stateful) bash


### stateless ###

.PHONY: build-stateless
build-stateless:
	docker build \
		--build-arg UID=$(uid) --build-arg GID=$(gid) \
		--label $(label) -t $(image_tag_stateless) -f $(dockerfile_stateless) .

$(nix_root):
	mkdir -p -m 0755 $@

$(nix_root)/.installed: build $(nix_root)
	docker run --privileged --rm --label $(label) -w /home/x \
		--mount type=bind,src=$(abspath $(nix_root)),dst=/nix \
		$(image_tag_stateless) flock /nix/.installed.lock bash /setup.sh

.PHONY: run-stateless
run-stateless: build-stateless $(nix_root)/.installed
	docker run --privileged -d --name $(container_name_stateless) --label $(label) \
		--mount type=bind,src=$(abspath $(nix_root)),dst=/nix \
		--mount type=bind,src=$(abspath $(icecap_root)),dst=/icecap \
		$(image_tag_stateless) sleep inf

.PHONY: exec-stateless
exec-stateless:
	docker exec -it $(container_name_stateless) bash


### common ###

.PHONY: logs
logs:
	for id in $$(docker ps -aq -f "label=$(label)"); do \
		docker logs $$id; \
	done

.PHONY: clean
clean:
	for id in $$(docker ps -aq -f "name=$(container_name_stateless)"); do \
		docker rm -f $$id; \
	done

.PHONY: deep-clean
deep-clean: clean
	for id in $$(docker ps -aq -f "label=$(label)"); do \
		docker rm -f $$id; \
	done
	if [ -d $(nix_root) ]; then \
		chmod -R u+w $(nix_root); \
		rm -rf $(nix_root); \
	fi
