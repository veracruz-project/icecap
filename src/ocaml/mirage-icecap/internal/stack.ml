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
    ip_addr: Ipaddr.V4.t;
    mac_addr: Macaddr.t;
}

let create config =
    let net = {
        STACK.NET.mac = config.mac_addr;
        mtu = 2048;
        stats = Mirage_net.Stats.create ();
    } in

    let%lwt e = STACK.ETH.connect net in
    let%lwt a = STACK.ARP.connect e in
    let%lwt c = STACK.CLOCK.connect () in
    let%lwt i = STACK.IPV4.connect c e a in
    let%lwt icmp = STACK.ICMPV4.connect i in
    let%lwt udp = STACK.UDP.connect i in
    let%lwt tcp = STACK.TCP.connect i c in
    let%lwt tcpip = STACK.TCPIP.connect net e a i icmp udp tcp in

    let%lwt () = STACK.IPV4.set_ip (STACK.TCPIP.ipv4 tcpip) config.ip_addr in
    Lwt.return tcpip
