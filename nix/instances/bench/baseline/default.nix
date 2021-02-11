{ lib, buildPackages, runCommand, writeScript, writeText, callPackage
, virtUtils, icecapPlat, linuxKernel
, runPkgs, pkgs_linux
, icecapExtraConfig
}:

with lib;

let

  pkgs = pkgs_linux;
  inherit (pkgs_linux) nixosLite;

in

self: with self;

{

  linux = {
    host = {
      virt = callPackage ./linux-kernel/host/virt {};
      rpi4 = callPackage ./linux-kernel/host/rpi4 {};
    };
  };

  hostKernelParams = [
    "loglevel=7"
  ] ++ lib.optionals (icecapPlat == "virt") [
    "console=ttyAMA0"
  ] ++ lib.optionals (icecapPlat == "rpi4") [
    "console=ttyS0,115200" # NOTE firmware was silently changing ttyAMA in cmdline.txt to ttyS0 in device tree
  ];

  hostKernel = linux.host.virt.kernel;
  hostInitramfs = "TODO";

  run = writeScript "run.sh" (with runPkgs; with virtUtils; ''
    ${runPkgs.qemu-aarch64}/bin/qemu-system-aarch64 \
      -machine virt,virtualization=on \
      -cpu cortex-a72 \
      -m 2048 \
      -nographic \
      -serial mon:stdio \
      -device virtio-9p-device,mount_tag=store,fsdev=store \
      -fsdev local,id=store,security_model=none,readonly,path=/nix/store \
      -kernel ${hostKernel} \
      -initrd ${hostInitramfs} \
      -append '${lib.concatStringsSep " " hostKernelParams}'

  '');

  test = pkgs.writeScript "test" ''
    #!${pkgs_linux.runtimeShell}
    rm -f /tmp/firecracker.socket
    touch log_fifo
    touch metrics_fifo
    ${pkgs_linux.icecap.firecracker-prebuilt}/bin/firecracker \
      --seccomp-level 0 \
      --config-file ${config} \
      --no-api
  '';
      # --api-sock /tmp/firecracker.socket

  test-firectl = pkgs.writeScript "test" ''
    #!${pkgs_linux.runtimeShell}
    ${pkgs_linux.icecap.firectl}/bin/firectl \
      --firecracker-binary=${pkgs_linux.icecap.firecracker}/bin/firecracker \
      --kernel=${linuxKernel.guest.kernel} \
      --kernel-opts="${"TODO"}" \
      --root-drive="${"TODO"}" \
      -d \
      "$@"
  '';

  config =
    let
      kernel_image_path = linuxKernel.guest.kernel;
      boot_args = "keep_bootcon console=ttyS0 reboot=k panic=1 pci=off loglevel=8";
      initrd_path = "TODO";
    in pkgs.writeText "config.json" ''
      {
        "boot-source": {
          "kernel_image_path": "${kernel_image_path}",
          "boot_args": "${boot_args}",
          "initrd_path": "${initrd_path}"
        },
        "logger": {
          "log_fifo": "/proc/self/fd/2",
          "metrics_fifo": "metrics_fifo",
          "level": "Debug"
        },
        "drives": [
        ],
        "machine-config": {
          "vcpu_count": 1,
          "mem_size_mib": 512
        }
      }
    '';

}
