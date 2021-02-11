let err exn =
    Logs.err (fun m -> m "main: %s%s" (Printexc.to_string exn) (Printexc.get_backtrace ()));
    exit 1
