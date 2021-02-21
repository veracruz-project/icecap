open Base
open Lwt.Infix
open OS.STACK

let parse_config obj : OS.config =
    let open Yojson.Safe.Util in
    {
        mac = Macaddr.of_string_exn (to_string (member "mac" obj));
        ip = Ipaddr.V4.of_string_exn (to_string (member "ip" obj));
        network = Ipaddr.V4.Prefix.of_string_exn (to_string (member "network" obj));
        gateway = Option.map ~f:Ipaddr.V4.of_string_exn (to_string_option (member "gateway" obj));
    }

let test_echo_server config : unit Lwt.t =
    let%lwt tcpip = OS.create config in

    let rec serve flow =
        let rec loop () =
            let%lwt result = TCP.read flow in
            match result with
            | Error e -> raise (Failure "tcp read error")
            | Ok `Eof -> begin
                Logs.info (fun m -> m "tcp eof");
                let%lwt () = TCP.close flow in
                Lwt.return_unit
            end
            | Ok (`Data buf) -> begin
                Logs.info (fun m -> m "tcp read:\n%s" (Hex.hexdump_s ~print_chars:false (Hex.of_cstruct buf)));
                let%lwt r = TCP.write flow buf in
                begin match r with
                | Error e -> raise (Failure "tcp write error")
                | Ok () -> loop ()
                end
            end
        in loop ()
    in

    TCPIP.listen_tcpv4 tcpip 8080 serve;
    TCPIP.listen tcpip

let test_timer () : unit Lwt.t =
    let rec loop () =
        Logs.info (fun m -> m "test");
        let%lwt () = OS.sleep_ns 1_000_000_000L in
        loop ()
    in loop ()

let err exn =
    Logs.err (fun m -> m "main: %s%s" (Exn.to_string exn) (Printexc.get_backtrace ()));
    exit 1

let main (raw_arg: bytes) =
    Logs.set_reporter (Logs_fmt.reporter ());
    Logs.set_level (Some Logs.Info);
    (* Logs.set_level (Some Logs.Debug); *)
    let obj = Yojson.Safe.from_string (Bytes.to_string raw_arg) in
    Logs.info (fun m -> m "arg: %a" Yojson.Safe.pp obj);
    Lwt.async_exception_hook := err;
    (* OS.run (test_timer ()); *)
    OS.run (test_echo_server (parse_config (Yojson.Safe.Util.member "network_config" obj)));
    0
