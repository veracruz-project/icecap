open Base

let main (raw_arg: bytes) =
    Logs.set_reporter (Logs_fmt.reporter ());
    Logs.set_level (Some Logs.Info);
    let obj = Yojson.Safe.from_string (Bytes.to_string raw_arg) in
    Logs.info (fun m -> m "arg: %a" Yojson.Safe.pp obj);
    0
