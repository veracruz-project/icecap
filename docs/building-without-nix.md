# Building without Nix

Upstream IceCap development, testing, and CI use a Nix-based build system.
However, care has been taken to ensure that the IceCap source code itself is
build-system agnostic. Downstream projects may opt to create an "ad-hoc" build
for a particular configuration of IceCap.

The [reference ad-hoc
build](https://gitlab.com/arm-research/security/icecap/reference-ad-hoc-build)
demonstrates such a build. The build in that repository is accomplished without
Nix. That repository exists for the sole purpose of documentation.
