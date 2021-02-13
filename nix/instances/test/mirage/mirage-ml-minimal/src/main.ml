open Lwt.Infix
open OS.STACK

let config : OS.config = {
    mac = Macaddr.of_string_exn "00:0a:95:9d:68:16";
    ip = Ipaddr.V4.of_string_exn "192.168.1.2";
    network = Ipaddr.V4.Prefix.of_string_exn "192.168.1.0/24";
    gateway = Some (Ipaddr.V4.of_string_exn "192.168.1.1");
}

let err exn =
    Logs.err (fun m -> m "main: %s%s" (Printexc.to_string exn) (Printexc.get_backtrace ()));
    exit 1

let test_echo_server () : unit Lwt.t =
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
                (* Logs.info (fun m -> m "tcp read"); Hex.hexdump (Hex.of_cstruct buf); *)
                Logs.info (fun m -> m "tcp read:\n %s" (Hex.hexdump_s (Hex.of_cstruct buf)));
                let%lwt r = TCP.write flow buf in
                begin match r with
                | Error e -> raise (Failure "tcp write error")
                | Ok () -> Lwt.return_unit
                end;
                loop ()
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

let main (arg: bytes) =
    let arg = Yojson.Safe.from_string (Bytes.to_string arg) in
    Logs.set_reporter (Logs_fmt.reporter ());
    Logs.set_level (Some Logs.Info);
    Logs.info (fun m -> m "arg: %a" Yojson.Safe.pp arg);
    (* OS.run (test_timer ()); *)
    OS.run (test_echo_server ());
    0
