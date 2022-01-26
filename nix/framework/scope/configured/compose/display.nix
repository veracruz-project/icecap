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

in linkFarm "system" (lib.flatten [
  (link "image.elf" image)
  (sub "breakdown" (lib.flatten [
    (showSplit "elfloader" bootImages.loader)
    (showSplit "kernel" bootImages.kernel)
    (showSplit "root-task" bootImages.app)
    (link "kernel.dtb" attrs.kernel.dtb)
    (sub "components" (lib.flatten [
      (lib.mapAttrsToList showSplit cdlImages)
    ]))
    (sub "capdl-specification" (lib.flatten [
      (link "icecap.cdl" "${attrs.cdl}/icecap.cdl")
      (link "icecap.spec.c" "${attrs.app.spec}/spec.c")
      (link "frame-fill" "${attrs.cdl}/links")
      (link "workspace" attrs.cdl)
    ]))
  ]))
])
