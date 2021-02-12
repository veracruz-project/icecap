let main () =
    (* print_string "Hello, Wold!"; *)
    Logs.set_reporter (Logs_fmt.reporter ());
    Logs.set_level (Some Logs.Info);
    Logs.info (fun m -> m "starting");
    0
