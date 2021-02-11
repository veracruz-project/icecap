open Lwt.Infix
open Role
open Util
open Config

open OS
open OS.STACK

let client () =
    let%lwt tcpip = OS.create client_config in

    let udp = TCPIP.udpv4 tcpip in
    let%lwt r = UDP.write server_config.ip_addr 1337 udp (Cstruct.of_string "A Test") in
    let%lwt () =
        begin match r with
        | Error _ ->
            raise (Failure "udp write failed");
            Lwt.return_unit
        | Ok () ->
            Logs.info (fun m -> m "udp success");
            Lwt.return_unit
        end
    in

    let tcp = TCPIP.tcpv4 tcpip in
    let t_start = OS.Icecap.Time.get_time_ns () in
    let%lwt r = TCP.create_connection tcp (server_config.ip_addr, 1337) in
    let%lwt () =
        begin match r with
        | Error _ ->
            raise (Failure "tcp connection failed");
            Lwt.return_unit
        | Ok flow ->
            let%lwt r = TCP.write flow (Cstruct.of_string "A TCP Test") in
            begin match r with
            | Error _ ->
                raise (Failure "tcp write failed");
                Lwt.return_unit
            | Ok () ->
                Lwt.return_unit
            end;
            let%lwt r = TCP.read flow in
            begin match r with
            | Error _ ->
                raise (Failure "tcp read failed");
                Lwt.return_unit
            | Ok (`Data bs) ->
                begin match Cstruct.to_string bs with
                | "echo" ->
                    Logs.info (fun m -> m "tcp success");
                    Lwt.return_unit
                | _ ->
                    raise (Failure "tcp read bad");
                    Lwt.return_unit
                end;
            end;
            let%lwt () = TCP.close flow in
            Lwt.return_unit
        end
    in
    let t_end = OS.Icecap.Time.get_time_ns () in
    (* let () = Logs.info (fun m -> m "delta: %Li" (Int64.sub t_end t_start)) in *)
    let () = Logs.info (fun m -> m "delta: %Li" (Int64.sub t_end t_start)) in
    (* let () = Printf.printf "delta: %Li" (Int64.sub t_end t_start) in *)

    (* Lwt.return_unit *)
    OS.sleep_ns 60_000_000_000L

let server () =
    let%lwt tcpip = OS.create server_config in

    let udp_handler ~src ~dst ~src_port buf =
        Logs.info (fun m -> m "udp read '%s'" (Cstruct.to_string buf));
        Lwt.return_unit
    in

    let tcp_handler flow =
        let rec loop () =
            let%lwt r = TCP.read flow in
            begin match r with
            | Error x -> raise (Failure "tcp read error")
            | Ok `Eof -> Lwt.return_unit
            | Ok (`Data b) ->
                Logs.info (fun m -> m "tcp read %s" (Cstruct.to_string b));
                Lwt.return_unit
            end;
            let%lwt r = TCP.write flow (Cstruct.of_string "echo") in
            begin match r with
            | Error _ ->
                raise (Failure "tcp write failed");
                Lwt.return_unit
            | Ok () ->
                Lwt.return_unit
            end;
            loop ()
        in loop ()
    in

    TCPIP.listen_udpv4 tcpip 1337 udp_handler;
    TCPIP.listen_tcpv4 tcpip 1337 tcp_handler;
    TCPIP.listen tcpip

let go () : unit Lwt.t = match whoami () with
    | Client -> client ()
    | Server -> server ()

let client_ping () =
    let%lwt tcpip = OS.create client_config in
    let udp = TCPIP.udpv4 tcpip in
    let rec loop () =
        let t_start = OS.Icecap.Time.get_time_ns () in
        let%lwt r = UDP.write server_config.ip_addr 1337 udp (Cstruct.of_string (Int64.to_string t_start)) in
        begin match r with
            | Error _ -> raise (Failure "udp write failed");
            | Ok () -> ();
        end;
        let%lwt () = OS.sleep_ns 1_000_000_000L in
        loop ()
    in
    let%lwt () = loop () in
    Lwt.return_unit

let ms_of_d t_start t_end =
    let d = Int64.sub t_end t_start in
    let ms = Int64.to_float d /. 1000000. in
    ms

let show_ms ms = Logs.info (fun m -> m "ms = %F" ms)

let server_ping () =
    let%lwt tcpip = OS.create server_config in

    let udp_handler ~src ~dst ~src_port buf =
        let t_end = OS.Icecap.Time.get_time_ns () in
        let t_start = Int64.of_string (Cstruct.to_string buf) in
        let d = Int64.sub t_end t_start in
        let ms = Int64.to_float d /. 1000000. in
        Logs.info (fun m -> m "ms = %F" ms);
        Lwt.return_unit
    in

    TCPIP.listen_udpv4 tcpip 1337 udp_handler;
    TCPIP.listen tcpip

let go_ping () : unit Lwt.t = match whoami () with
    | Client -> client_ping ()
    | Server -> server_ping ()

let client_thru () =
    let%lwt tcpip = OS.create client_config in

    let tcp = TCPIP.tcpv4 tcpip in

    let rec outer () =
        let t_start = OS.Icecap.Time.get_time_ns () in
        let%lwt r = TCP.create_connection tcp (server_config.ip_addr, 1337) in
        let%lwt () = begin match r with
        | Error _ -> raise (Failure "tcp connection failed")
        | Ok flow ->
            let rec loop n =
                let%lwt r = TCP.read flow in
        (* let%lwt () = OS.sleep_ns 1_000_000_000L in *)
                let%lwt () = begin match r with
                | Error _ ->
                    raise (Failure "tcp read error")
                | Ok `Eof ->
                    Lwt.return_unit
                | Ok (`Data b) ->
                    (* Logs.info (fun m -> m "tcp read %s" (Cstruct.to_string b)); *)
                    loop n
                end in
                Lwt.return_unit
            in
            let%lwt n = loop 0 in
            let t_end = OS.Icecap.Time.get_time_ns () in
            show_ms (ms_of_d t_start t_end);
            Lwt.return_unit
        end in
        let%lwt () = OS.sleep_ns 1_000_000_000L in
        outer ()
    in

    let%lwt () = outer () in

    (* Lwt.return_unit *)
    OS.sleep_ns 60_000_000_000L

let server_thru () =
    let%lwt tcpip = OS.create server_config in

    let tcp_handler flow =
        let rec loop i =
            match i with
            | 0 -> Lwt.return_unit
            | _ ->
                let%lwt r = TCP.write flow (Cstruct.of_string "0123") in
                let%lwt () = begin match r with
                | Error _ ->
                    raise (Failure "tcp write failed");
                | Ok () ->
                    Lwt.return_unit
                end in
                loop (i - 1)
        in
        let%lwt () = loop 8192 in
        let%lwt () = TCP.close flow in
        Lwt.return_unit
    in

    TCPIP.listen_tcpv4 tcpip 1337 tcp_handler;
    TCPIP.listen tcpip

let go_thru () : unit Lwt.t = match whoami () with
    | Client -> client_thru ()
    | Server -> server_thru ()

let main () =
    Logs.set_reporter (Logs_fmt.reporter ());
    Logs.set_level (Some Logs.Info);
    Logs.info (fun m -> m "starting");
    Lwt.async_exception_hook := err;
    (* OS.run (go ()); *)
    (* OS.run (go_ping ()); *)
    OS.run (go_thru ());
    0
