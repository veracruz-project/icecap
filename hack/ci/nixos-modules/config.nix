{ lib, config, pkgs, ... }:

let
  cfg = config.icecap.ci;

  env = pkgs.buildEnv {
    name = "env";
    paths = with pkgs; [
      cfg.gitlab-runner.nixPackage
      cacert
      git
      gnumake
    ];
  };

in {
  options = {

    icecap.ci.gitlab-runner.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    # File should contain at least these two variables:
    # `CI_SERVER_URL`
    # `REGISTRATION_TOKEN`
    icecap.ci.gitlab-runner.registrationConfigFile = lib.mkOption {
      type = lib.types.path;
    };

    icecap.ci.gitlab-runner.nixPackage = lib.mkOption {
      type = lib.types.unspecified;
      default = pkgs.nix;
    };

    icecap.ci.nix-serve.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    icecap.ci.nix-serve.secretKeyFile = lib.mkOption {
      type = lib.types.path;
    };
  };

  config = lib.mkMerge [

    (lib.mkIf cfg.gitlab-runner.enable {

      boot.kernel.sysctl."net.ipv4.ip_forward" = true;

      virtualisation.docker.enable = true;

      # Adapted from https://nixos.wiki/wiki/Gitlab_runner
      services.gitlab-runner = {
        enable = true;
        services = {
          # Runner for building in Docker via host's nix-daemon.
          # Host's /nix/store will be readable in runner.
          nix = with lib;{
            registrationConfigFile = cfg.gitlab-runner.registrationConfigFile;
            dockerImage = "debian:bullseye-slim";
            dockerVolumes = [
              "/nix/store:/nix/store:ro"
              "/nix/var/nix/db:/nix/var/nix/db:ro"
              "/nix/var/nix/daemon-socket:/nix/var/nix/daemon-socket:ro"
            ];
            dockerDisableCache = true;
            preBuildScript = pkgs.writeScript "setup-container" ''
              # ...
            '';
            environmentVariables = {
              ENV = "/etc/profile";
              USER = "root";
              PATH = "${env}/bin:/bin:/sbin:/usr/bin:/usr/sbin";
              NIX_REMOTE = "daemon";
              NIX_SSL_CERT_FILE = "${env}/etc/ssl/certs/ca-bundle.crt";
              NIX_BUILD_SHELL = "bash";
            };
            tagList = [ "nix" ];
          };
        };
      };
    })

    (lib.mkIf cfg.nix-serve.enable {

      services.nix-serve = {
       enable = true;
       openFirewall = true;
       secretKeyFile = cfg.nix-serve.secretKeyFile;
     };
   })
 ];
}
