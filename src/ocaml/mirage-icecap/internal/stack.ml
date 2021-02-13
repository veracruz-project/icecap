module STACK = struct
    module NET = Net.N
    module ETH = Ethernet.Make(NET)
    module ARP = Arp.Make(ETH)(Time)
    module RAND : Mirage_random.C = Random_lame
    module CLOCK = Mclock
    module IPV4 = Static_ipv4.Make(RAND)(CLOCK)(ETH)(ARP)
    module ICMPV4 = Icmpv4.Make(IPV4)
    module UDP = Udp.Make(IPV4)(RAND)
    module TCP = Tcp.Flow.Make(IPV4)(Time)(CLOCK)(RAND)
    module TCPIP = Tcpip_stack_direct.Make(Time)(RAND)(NET)(ETH)(ARP)(IPV4)(ICMPV4)(UDP)(TCP)
end

type config = {
    mac: Macaddr.t;
    ip: Ipaddr.V4.t;
    network: Ipaddr.V4.Prefix.t;
    gateway: Ipaddr.V4.t option;
}

let create config =
    let ip = config.ip in
    let gateway = config.gateway in
    let network = config.network in
    let net = {
        STACK.NET.mac = config.mac;
        mtu = 2048; (* HACK *)
        stats = Mirage_net.Stats.create ();
    } in

    let%lwt e = STACK.ETH.connect net in
    let%lwt a = STACK.ARP.connect e in
    let%lwt c = STACK.CLOCK.connect () in
    let%lwt i = STACK.IPV4.connect ~ip ~network ~gateway c e a in
    let%lwt icmp = STACK.ICMPV4.connect i in
    let%lwt udp = STACK.UDP.connect i in
    let%lwt tcp = STACK.TCP.connect i c in
    let%lwt tcpip = STACK.TCPIP.connect net e a i icmp udp tcp in
    Lwt.return tcpip
