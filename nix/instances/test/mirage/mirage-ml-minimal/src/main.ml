let main (arg: bytes) =
    let arg = Yojson.Safe.from_string (Bytes.to_string arg) in
    Logs.set_reporter (Logs_fmt.reporter ());
    Logs.set_level (Some Logs.Info);
    Logs.info (fun m -> m "arg: %a" Yojson.Safe.pp arg);
    0
