external stub_num_ifaces: unit -> int = "stub_num_net_ifaces"
external stub_packet_poll: int -> bool = "stub_net_iface_poll"
external stub_packet_recv: int -> bytes = "stub_net_iface_rx"
external stub_packet_send: int -> bytes -> unit = "stub_net_iface_tx"
external stub_set_timeout_ns: int64 -> unit = "stub_set_timeout_ns"
external stub_get_time_ns: unit -> int64 = "caml_get_monotonic_time"
external stub_wfe: unit -> unit = "stub_wfe"

let wfe = stub_wfe

module Time = struct
    let set_timeout_ns = stub_set_timeout_ns
    let get_time_ns = stub_get_time_ns
end

module Net = struct

    let num_ifaces = stub_num_ifaces

    let poll = stub_packet_poll

    let recv = stub_packet_recv

    let send iface_id (packet : bytes) : unit =
        stub_packet_send iface_id packet

    let send_to_all (packet : bytes) : unit =
        Base.Sequence.(
            iter (range 0 (num_ifaces ())) (fun i -> send i packet)
        )

    let send_to_all_except (no : int) (packet : bytes) : unit =
        Base.Sequence.(
            iter (filter (range 0 (num_ifaces ())) (fun i -> i <> no)) (fun i -> send i packet)
        )

    let recv_from_any unit : (int * bytes) option =
        let rec loop i = let iface_id = i - 1 in match i with
            | 0 -> None
            | _ -> if poll iface_id then begin
                    let packet = recv iface_id in
                    Some (iface_id, packet)
                end else loop iface_id
        in loop (stub_num_ifaces ())

end
