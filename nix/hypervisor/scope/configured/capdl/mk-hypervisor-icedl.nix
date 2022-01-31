{ mkIceDL
, hypervisor-fdt-append-devices
, hypervisor-serialize-component-config
, hypervisor-serialize-event-server-out-index
}:

{ config, subcommand ? null, script ? null, command ? "python3 -m icecap_hypervisor.cli ${subcommand} $CONFIG -o $OUT_DIR" }:

(mkIceDL ({
  config = {
    hack_realm_affinity = 0;
  } // config;
} // (if script != null then {
  inherit script;
} else {
  inherit command;
}))).overrideAttrs (attrs: {
  nativeBuildInputs = attrs.nativeBuildInputs ++ [
    hypervisor-fdt-append-devices
    hypervisor-serialize-component-config
    hypervisor-serialize-event-server-out-index
  ];
})
