let client_config : OS.config = {
    ip_addr = Ipaddr.V4.of_string_exn "192.168.1.1";
    mac_addr = Macaddr.of_string_exn "00:0a:95:9d:68:16";
}

let server_config : OS.config = {
    ip_addr = Ipaddr.V4.of_string_exn "192.168.1.2";
    mac_addr = Macaddr.of_string_exn "00:0a:95:9d:68:17";
}
