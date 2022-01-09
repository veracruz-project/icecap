{ lib, config, pkgs, ... }:

with lib;

let
  cfg = config.instance;

in {
  config = mkMerge [
    {
      initramfs.extraUtilsCommands = ''
      '';

      initramfs.extraInitCommands = mkAfter ''
        # https://access.redhat.com/solutions/177953
        # https://www.redhat.com/files/summit/session-assets/2018/Performance-analysis-and-tuning-of-Red-Hat-Enterprise-Linux-Part-1.pdf
        # echo 10000000 > /proc/sys/kernel/sched_min_granularity_ns
        # echo 15000000 > /proc/sys/kernel/sched_wakeup_granularity_ns

        export iperf_affinity=0x4
        export realm_affinity=0x2

        # HACK
        . /etc/profile

        ${lib.optionalString cfg.autostart.enable ''
          auto &
        ''}
      '';

      initramfs.profile = ''
        auto() {
          ${lib.optionalString cfg.autostart.cpu ''
            for _ in $(seq 2); do
              cpu_bound
              sleep 5
            done
          ''}
          start_realm &
          start_iperf_server > /dev/null
        }

        start_realm() {
          taskset $realm_affinity icecap-host create 0 /spec.bin && \
            chrt -b 0 taskset $realm_affinity icecap-host run 0 0
        }

        destroy_realm() {
          icecap-host destroy 0
        }

        start_iperf_server() {
          chrt -b 0 iperf3 -s
        }

        stop_iperf_server() {
          pkill iperf3
        }

        benchmark_server() {
          icecap-host benchmark $1
        }

        cpu_bound_with_utilization() {
          benchmark_server start
          sysbench cpu --cpu-max-prime=20000 --num-threads=1 run
          benchmark_server finish
        }

        run_iperf_client_with_utilization() {
          reverse="--reverse"
          pin="taskset $iperf_affinity"

          benchmark_server start
          $pin chrt -b 0 iperf3 -c ${cfg.misc.net.realmAddr} $reverse > /dev/null
          benchmark_server finish
        }

        ### shortcuts ###

        s() {
          benchmark_server start
        }
        f() {
          benchmark_server finish
        }
      '';
    }
  ];
}
