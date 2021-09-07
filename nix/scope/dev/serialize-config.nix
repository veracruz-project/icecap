{ lib
, buildRustPackageIncrementally
, crateUtils, outerGlobalCrates
, linkFarm, writeText
}:

let

  mk = { name, type, crate ? null }:

    buildRustPackageIncrementally rec {

      layers =  [ [] ] ++ lib.optionals (crate != null) [ [ crate ] ];

      debug = true;

      rootCrate = crateUtils.mkCrate {

        nix.name = "serialize-${name}-config";

        nix.isBin = true;

        nix.src.store = linkFarm "src" [
          { name = "main.rs";
            path = writeText "main.rs" ''
              #![feature(type_ascription)]

              use std::marker::PhantomData;

              fn main() -> Result<(), std::io::Error> {
                  icecap_config_cli_core::main(PhantomData: PhantomData<${type}>)
              }
            '';
          }
        ];

        nix.localDependencies = [
          outerGlobalCrates.icecap-config-cli-core
        ] ++ lib.optionals (crate != null) [
          crate
        ];

        dependencies = {
          serde = "*";
          serde_json = "*";
          pinecone = "*";
        };
      };

    };

in {

  inherit mk;

  generic = mk {
    name = "generic";
    type = "serde_json::Value";
  };
  fault-handler = mk {
    name = "fault-handler";
    type = "icecap_fault_handler_config::Config";
    crate = outerGlobalCrates.icecap-fault-handler-config;
  };
  timer-server = mk {
    name = "timer-server";
    type = "icecap_timer_server_config::Config";
    crate = outerGlobalCrates.icecap-timer-server-config;
  };
  serial-server = mk {
    name = "serial-server";
    type = "icecap_serial_server_config::Config";
    crate = outerGlobalCrates.icecap-serial-server-config;
  };
  host-vmm = mk {
    name = "host-vmm";
    type = "icecap_host_vmm_config::Config";
    crate = outerGlobalCrates.icecap-host-vmm-config;
  };
  realm-vmm = mk {
    name = "realm-vmm";
    type = "icecap_realm_vmm_config::Config";
    crate = outerGlobalCrates.icecap-realm-vmm-config;
  };
  resource-server = mk {
    name = "resource-server";
    type = "icecap_resource_server_config::Config";
    crate = outerGlobalCrates.icecap-resource-server-config;
  };
  event-server = mk {
    name = "event-server";
    type = "icecap_event_server_config::Config";
    crate = outerGlobalCrates.icecap-event-server-config;
  };

}
