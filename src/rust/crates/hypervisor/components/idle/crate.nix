{ mkComponent, localCrates }:

mkComponent {
  nix.name = "idle";
  nix.local.dependencies = with localCrates; [
    icecap-std
  ];
  dependencies = {
    cortex-a = "*";
  };
  nix.hack.noDoc = true;
}
