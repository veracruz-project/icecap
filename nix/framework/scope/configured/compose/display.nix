{ lib, linkFarm
, composition
}:

with composition;

let
  sub = name': map ({ name, path }: {
    name = "${name'}/${name}";
    inherit path;
  });

  link = name: path: { inherit name path; };

  showSplit = name: { min, full }: [
    { name = "${name}.elf"; path = min; }
    { name = "${name}.debug.elf"; path = full; }
  ];

in linkFarm "icecap-hypervisor-firmware" (lib.flatten [
  (link "icecap.elf" image)
  (sub "breakdown" (lib.flatten [
    (showSplit "elfloader" images.loader)
    (showSplit "kernel" images.kernel)
    (showSplit "root-task" images.app)
    (link "kernel.dtb" components.kernel.dtb)
    (sub "components" (lib.flatten [
      (lib.mapAttrsToList showSplit cdlImages)
      # (link "host.u-boot.bin" components.u-boot)
    ]))
    (sub "capdl-specification" (lib.flatten [
      (link "icecap.cdl" "${components.cdl}/icecap.cdl")
      (link "icecap.spec.c" "${components.app.spec}/spec.c")
      (link "frame-fill" "${components.cdl}/links")
      (link "workspace" components.cdl)
    ]))
  ]))
])
