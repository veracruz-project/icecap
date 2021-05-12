{ stdenv, lib, linkFarm, writeText, cargoLockToNix, nixToToml }:

cargoLock:

let

  lock = cargoLockToNix cargoLock;

  vendored-sources = linkFarm "vendored-sources" (lib.mapAttrsToList (name: crate: {
    inherit name;
    path = crate;
  }) lock.source);

  config = {
    source = {
      crates-io.replace-with = "vendored-sources";
      vendored-sources.directory = vendored-sources;
    } // lib.listToAttrs (map (crateMeta: with crateMeta; {
      name = url;
      value = {
        git = url;
        "${param.key}" = param.value;
        replace-with = "vendored-sources";
      };
    }) (lib.filter (crateMeta: crateMeta.source == "git") (lib.mapAttrsToList (k: v: v.crateMeta) lock.source)));
  };

in nixToToml config // {
  inherit config lock vendored-sources;
}
