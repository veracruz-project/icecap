{ lib, pkgs, instances }:

rec {
  cases = {
    # TODO
  };

  runAll = mkRunAll cases;

  mkRunAll = cases':
    with pkgs.dev;
    writeScript "run-all" ''
      #!${bash}/bin/bash
      set -e

      ${lib.concatStrings (lib.flip lib.mapAttrsToList cases' (name: autoScript: ''
        echo "<<< running case: ${name} >>>"
        ${autoScript}
      ''))}
    '';

  automateQemuBasic = { script, timeout }:
    with pkgs.dev;
    writeScript "automate-qemu" ''
      #!${bash}/bin/bash
      set -eu

      script=${script}
      timeout_=${toString timeout}

      echo "running '$script' with timeout ''${timeout_}s"

      # the odd structure of this next part is due to bash's limitations on
      # pipes, process substition, and coprocesses.

      coproc $script < /dev/null
      result=$( \
        timeout $timeout_ bash -c \
          'head -n1 <(bash -c "tee >(cat >&2)" | grep -E -a --line-buffered --only-matching "TEST_(PASS|FAIL)")' \
          <&''${COPROC[0]} \
      )
      kill $COPROC_PID

      echo "result: '$result'"
      [ "$result" == "TEST_PASS" ]
    '';
}
