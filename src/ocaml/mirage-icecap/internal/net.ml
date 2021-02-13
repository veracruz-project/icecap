module N = struct

    (* TODO *)
    let disconnect t = Lwt.return ()

    type 'a io = 'a Lwt.t
    type buffer = Cstruct.t
    type macaddr = Macaddr.t
    type error = Mirage_net.Net.error

    let pp_error = Mirage_net.Net.pp_error

    type t = {
        mac: Macaddr.t;
        mtu: int;
        stats: Mirage_net.stats;
    }

    let write t ~size fillf =
        let buf = Cstruct.create size in
        Cstruct.memset buf 0;
        let _ = fillf buf in
        Icecap.Net.send_to_all (Cstruct.to_bytes buf); (* HACK *)
        Lwt.return (Ok ())

    let listen t ~header_size:_ receive_callback =
        let rec loop () =
            let%lwt pkt = Loop.read_packet () in
            Lwt.async (fun () -> receive_callback (Cstruct.of_bytes pkt));
            loop ()
        in
        let%lwt () = loop () in
        (* TODO *)
        Lwt.return (Ok ())

    let mac t = t.mac
    let mtu t = t.mtu (* TODO mtu > 16384 does not work: https://github.com/mirage/mirage-tcpip/blob/451c5666d5a486620d89a4b95d89d40be51c79ed/src/tcp/user_buffer.ml#L146 *)
    let get_stats_counters t = t.stats
    let reset_stats_counters t = Mirage_net.Stats.reset t.stats
end
