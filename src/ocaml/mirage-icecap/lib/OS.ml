module STACK = Os_icecap.Stack.STACK

module Icecap = Os_icecap.Icecap

type config = Os_icecap.Stack.config
let create = Os_icecap.Stack.create

let sleep_ns = Os_icecap.Time.sleep_ns
let run = Os_icecap.Loop.run

(* debug *)
let wfe = Os_icecap.Icecap.wfe
