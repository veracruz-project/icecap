{ lib, config, pkgs, ... }:

with lib;

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

    icecap.ci.gitlab-runner.enable = mkOption {
      type = types.bool;
      default = false;
    };

    # File should contain at least these two variables:
    # `CI_SERVER_URL`
    # `REGISTRATION_TOKEN`
    icecap.ci.gitlab-runner.registrationConfigFile = mkOption {
      type = types.path;
    };

    icecap.ci.gitlab-runner.tagList = mkOption {
      type = types.listOf types.str;
      default = [ "nix-${pkgs.hostPlatform.system}" ];
    };

    icecap.ci.gitlab-runner.nixPackage = mkOption {
      type = types.package;
      default = config.nix.package;
    };
  };

  config = mkIf cfg.gitlab-runner.enable {

    boot.kernel.sysctl."net.ipv4.ip_forward" = true;

    virtualisation.docker.enable = true;

    services.gitlab-runner = {
      enable = true;
      services = {
        # Runner for building in Docker via host's nix-daemon.
        # Host's /nix/store will be readable in runner.
        nix = with lib; {
          dockerDisableCache = true;
          dockerImage = "debian:bullseye-slim";
          dockerVolumes = [
            "/nix/store:/nix/store:ro"
            "/nix/var/nix/db:/nix/var/nix/db:ro"
            "/nix/var/nix/daemon-socket:/nix/var/nix/daemon-socket:ro"
          ];
          environmentVariables = {
            ENV = "/etc/profile";
            USER = "root";
            PATH = "${env}/bin:/bin:/sbin:/usr/bin:/usr/sbin";
            NIX_REMOTE = "daemon";
            NIX_SSL_CERT_FILE = "${env}/etc/ssl/certs/ca-bundle.crt";
            NIX_BUILD_SHELL = "bash";
          };
          registrationConfigFile = cfg.gitlab-runner.registrationConfigFile;
          tagList = cfg.gitlab-runner.tagList;
        };
      };
    };
  };

}
