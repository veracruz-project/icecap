open Lwt.Infix

let listeners : (bytes Lwt.u) Lwt_dllist.t = Lwt_dllist.create ()

let read_packet (() : unit) : bytes Lwt.t =
    let t, u = Lwt.wait () in
    let _ = Lwt_dllist.add_r u listeners in
    t

let iter block =
    let do_block () =
        if block
        then begin
            begin match Time.select_next () with
                | Some ns -> Icecap.Time.set_timeout_ns ns
                | None -> ()
            end;
            Icecap.wfe ()
        end
    in
    if Lwt_dllist.is_empty listeners then do_block () else begin
        let rec loop () =
            match Icecap.Net.recv_from_any () with
                | None -> do_block ()
                | Some (iface_id, packet) -> begin
                    (* TODO is this right? what about threads waiting on other events? *)
                    let listener = Lwt_dllist.take_l listeners in
                    Lwt.wakeup_later listener packet;
                    loop ()
                end
        in loop ()
    end

(* TODO Lwt.pause vs (unix) Lwt_main.yield *)
let rec run (t : 'a Lwt.t) : 'a =
    Lwt.wakeup_paused ();
    Time.restart_threads Icecap.Time.get_time_ns;
    match Lwt.poll t with
    | Some x -> x
    | None ->
        iter (Lwt.paused_count () = 0);
        run t
